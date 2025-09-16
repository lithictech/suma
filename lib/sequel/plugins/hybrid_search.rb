# frozen_string_literal: true

require "sequel/sequel_hybrid_search"
require "pgvector"

module Sequel::Plugins::HybridSearch
  HASH_VERSION = "v2"

  DEFAULT_OPTIONS = {
    content_column: :search_content,
    vector_column: :search_embedding,
    hash_column: :search_hash,
    language: "english",
    # This is RFF, as explained here:
    # https://jkatz05.com/post/postgres/hybrid-search-postgres-pgvector/
    # Should be 0-100.
    # Basically, higher values mean that the difference between the better and worse ranked answers
    # are compressed; lower values mean the differences are more extreme.
    # Because semantic search gives us different vectors for nearly all rows,
    # we can use a higher value: there may not be a meaningful difference
    semantic_rrf_k: 75,
    # See +semantic_rrf_k+, but for keyword search.
    # Because many rows will give the same value, the difference between rankings is very important.
    # For example, "user smithers" may give a rank of 1 to smithers, and 2 to every other user.
    # Compare this to semantic rrf, where 1 may be smithers, and all the other results (who are not smithers)
    # are ranked 2, 3, 4, 5, etc. on.
    keyword_rrf_k: 0,
    # Weigh the semantic search more or less heavily.
    # Set to 0 to not consider its results,
    # which can be useful in unit tests which test ordering
    # (since semantic search is not deterministic).
    # We weigh keyword results more highly since,
    # for this simple vector search, they map more cleanly to expectations.
    semantic_scale: 0.5,
    # Same as +semantic_scale+ but for the keyword/text search.
    keyword_scale: 1,
    # Filter out rows with lower than this trigram similarity score.
    trigram_threshold: 0.3,
    # How many times to retry if reindexing fails (API server is down, etc.).
    indexing_retries: 4,
    # False to avoid registering in +SequelHybridSearch.indexable_models+.
    indexable: true,
    # Called to figure out how long to sleep between retries.
    # By default, use exponential backoff with a base delay of 4 seconds.
    indexing_backoff: ->(attempt) { 4 * (2**(attempt - 1)) },
  }.freeze

  def self.apply(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    # The search implementation columns can be quite large; there's almost no reason to return them,
    # since they're just used by the database.
    # The hash column is used by the 'hash changed' instance check;
    # but this will run relatively rarely as compared to fetching data,
    # so it's better to make an additional database call for these fields on update
    # (which is already relatively slower, so an additional read is ok given the fact we just wrote).
    model.plugin :lazy_attributes, opts[:content_column], opts[:hash_column], opts[:vector_column]
    model.plugin :insert_returning_select
    model.plugin :pgvector, opts[:vector_column]
  end

  def self.configure(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    model.hybrid_search_content_column = opts[:content_column]
    model.hybrid_search_vector_column = opts[:vector_column]
    model.hybrid_search_hash_column = opts[:hash_column]
    model.hybrid_search_language = opts[:language]
    model.hybrid_search_semantic_rrf_k = opts[:semantic_rrf_k]
    model.hybrid_search_keyword_rrf_k = opts[:keyword_rrf_k]
    model.hybrid_search_semantic_scale = opts[:semantic_scale]
    model.hybrid_search_keyword_scale = opts[:keyword_scale]
    model.hybrid_search_trigram_threshold = opts[:trigram_threshold]
    model.hybrid_search_indexing_retries = opts[:indexing_retries]
    model.hybrid_search_indexing_backoff = opts[:indexing_backoff]
    SequelHybridSearch.indexable_models << model unless opts[:indexable] == false
    # The :pgvector plugin deserializes by overriding `[]`, which isn't called by the :lazy_attributes plugin.
    # So we need to redefine a getter that will deserialize.
    model.define_method(opts[:vector_column]) do
      ::Pgvector.decode(super())
    end
  end

  module DatasetMethods
    # Run a hybrid search. A hybrid search is a combination of:
    # Keyword search: Any term in the query +q+ must be present in the row's search content.
    # Semantic search: Get the embeddings for query +q+ and run a RAG against the row embeddings.
    # This means that:
    # - Only rows that match a word in +q+ will be returned
    #   (so use the table name to find all results, like 'Users named Tim').
    # - Rows with better keyword matches will rank higher.
    # - Rows with better semantic matches will rank higher (though keywords are more important).
    #
    # Limit/offset pagination may get very slow,
    # even moreso than normal offset/limit pagination,
    # which has this problem (since skipped rows still need to be ranked).
    # To avoid this, you can use cursor-based pagination by filtering the dataset,
    # like `ds.where { id > last_result_id }.hybrid_search(...)`.
    def hybrid_search(q)
      (pk = self.model.primary_key) or raise "model #{self.model} must have a primary key"
      vec_col = self.model.hybrid_search_vector_column
      content_col = self.model.hybrid_search_content_column
      query_embedding = SequelHybridSearch.embedding_generator.get_embedding(q)
      q = q.strip
      vec = Pgvector.encode(query_embedding)
      lang = self.model.hybrid_search_language
      # Match certain queries against all rows, requires an OR 1=1 on the filter
      should_match_all = q.blank? || q == "*"
      # Queries look like "users named Tim who were created in the last 5 days".
      # We need to use an OR against all words (rather than AND/FOLLOWED BY),
      # so that relevant terms like 'Tim' are matched, but irrelevant ones like 'days' are not.
      # This depends on only using as tsvector the unique/dynamic content for each row's search text,
      # so 'Tim' is present for rows with the name 'Tim'.
      processed_query = q.gsub(" ", " OR ")
      # Based on https://github.com/pgvector/pgvector-python/blob/master/examples/hybrid_search/rrf.py
      # With changes to get it to work as a standard dataset.
      # First, get a dataset which filters out non-matching rows,
      # and selects the text ranking of each matched row, along with the pk of the row.

      # In our queries, it helps to refer to a 'query' value
      table_and_tsquery = Sequel.function(:websearch_to_tsquery, lang, processed_query).as(:query)

      # Establish the filter to limit rows in the keyword (and semantic) query.
      # Rows must match the tsvector OR trigram filters.
      if should_match_all
        matchallexpr = " OR 1=1"
        matches_trigram = Sequel[1 => 1]
      else
        matches_trigram = Sequel.function(:word_similarity, q, content_col) >
          self.model.hybrid_search_trigram_threshold
        matchallexpr = ""
      end
      matches_tsquery = Sequel.lit("to_tsvector(?, #{content_col}) @@ query#{matchallexpr}", lang)

      # Rank text-filtered rows based on their text match.
      # We use both text vector AND trigram similarity to figure out what rows to include, and how to rank.
      kw_search = self.model.
        from(self.select(Sequel.lit("*")), table_and_tsquery).
        where(matches_tsquery | matches_trigram).
        select(
          Sequel[pk].as(:id),
          Sequel.function(:rank).
            over(
              order: Sequel.desc(
                # To get the ordering, multiply the fulltext and trigram rankings by each other.
                # We cannot normalize trigram and tsvector values against each other, unfortunately,
                # so this is what we're left with. Rows that rank very low in either one
                # will be ranked lower; rows that are higher in both will do better.
                Sequel.function(
                  :ts_rank_cd,
                  Sequel.function(:to_tsvector, lang, content_col),
                  :query,
                  # Use 32 to ensure we're between 0-1.
                  # I'm not certain this is required though.
                  # https://www.postgresql.org/docs/current/textsearch-controls.html#TEXTSEARCH-RANKING
                  32,
                ) * Sequel.function(:word_similarity, q, content_col),
              ),
            ).
            as(:rank),
        )

      # Now for semantic search. We still need to do the keyword matching,
      # so we only rank rows that are possible search candidates.
      semantic_search = self.model.
        from(self.select(Sequel.lit("*")), table_and_tsquery).
        where(matches_tsquery).
        select(
          Sequel[pk].as(:id),
          Sequel.function(:rank).
            over(order: Sequel.lit("#{vec_col} <=> ?", vec)).
            as(:rank),
        )

      # Now join on our two queries, and order it based on their combined ranking.
      rank_order = [
        [self.model.hybrid_search_semantic_rrf_k, :semantic_search, self.model.hybrid_search_semantic_scale],
        [self.model.hybrid_search_keyword_rrf_k, :kw_search, self.model.hybrid_search_keyword_scale],
      ].sum do |(rrf, subq, scale)|
        Sequel.function(:coalesce, Sequel[1.0] / (Sequel[rrf] + Sequel[subq][:rank]), 0.0) * scale
      end
      ds = self.model
      # Join the full dataset against the keyword search (which is derived from 'self'),
      # to limit rows.
      ds = ds.join(kw_search.as(:kw_search), id: pk)
      # We want to return rows that don't match any in the semantic search, so use a left_join.
      ds = ds.left_join(semantic_search.as(:semantic_search), id: pk)
      # Unfortunately the left_join messes up columns, so reselect them
      ds = ds.select(Sequel[self.model.table_name][Sequel.lit("*")])
      # Select the total rank as a field and then order by it
      ds = ds.select_append(rank_order.as(:_shs_total_rank))
      ds = ds.order(Sequel.desc(:_shs_total_rank))
      # Add additional columns to debug rankings.
      ds = ds.select_append(
        Sequel[:kw_search][:rank].as(:_shs_kw_rank),
        Sequel[:semantic_search][:rank].as(:_shs_semantic_rank),
      )
      return ds
    end
  end

  module ClassMethods
    attr_accessor :hybrid_search_content_column,
                  :hybrid_search_vector_column,
                  :hybrid_search_hash_column,
                  :hybrid_search_language,
                  :hybrid_search_semantic_rrf_k,
                  :hybrid_search_keyword_rrf_k,
                  :hybrid_search_semantic_scale,
                  :hybrid_search_keyword_scale,
                  :hybrid_search_trigram_threshold,
                  :hybrid_search_indexing_retries,
                  :hybrid_search_indexing_backoff

    def hybrid_search_reindex_all
      did = 0
      enum = self.dataset.respond_to?(:each_cursor_page) ? :each_cursor_page : :paged_each
      self.dataset.send(enum) do |m|
        m.hybrid_search_reindex
        did += 1
      end
      return did
    end

    def hybrid_search_reindex_model(model_pk)
      m = self.with_pk!(model_pk)
      m.hybrid_search_reindex
      return m
    end
  end

  module InstanceMethods
    def after_create
      super
      self._run_after_model_hook
    end

    def after_update
      super
      self._run_after_model_hook
    end

    def _run_after_model_hook
      if SequelHybridSearch.indexing_mode == :async
        # Because we're re-fetching the model, we need to make sure it happens after the DB sees the update.
        self.db.after_commit do
          # We must refetch the model to index since it happens on another thread.
          SequelHybridSearch.threadpool.post do
            self.model.hybrid_search_reindex_model(self.pk)
          end
        end
      elsif SequelHybridSearch.indexing_mode == :sync
        self.hybrid_search_reindex
      end
    end

    def hybrid_search_reindex(attempt: 1)
      model = self.model
      text = self.hybrid_search_text
      hash_version, hash_content, hash_ts = self._hybrid_search_hash_changed(text)
      return if hash_version.nil?
      em = SequelHybridSearch.embedding_generator.get_embedding(text)
      content = _hybrid_search_text_to_storage(text)
      # We update when any of these are true:
      # - The old hash doesn't begin with the current hash version string.
      # - The hashed content is different from the new content AND
      #   the timestamp of when we fetched the data is after the stored timestamp.
      this_ds = self.this.where(
        Sequel[model.hybrid_search_hash_column => nil] |
        ~Sequel.like(model.hybrid_search_hash_column, "#{hash_version}.%") |
        (
          (Sequel.function(:split_part, model.hybrid_search_hash_column, ".", 2) !~ hash_content) &
          (Sequel.function(:split_part, model.hybrid_search_hash_column, ".", 3).cast(:bigint) < hash_ts)
        ),
      )
      this_ds.update(
        model.hybrid_search_content_column => content,
        model.hybrid_search_vector_column => Pgvector.encode(em),
        model.hybrid_search_hash_column => "#{hash_version}.#{hash_content}.#{hash_ts}",
      )
    rescue StandardError => e
      raise e if attempt > model.hybrid_search_indexing_retries
      Kernel.sleep(model.hybrid_search_indexing_backoff.call(attempt))
      self.hybrid_search_reindex(attempt: attempt + 1)
    end

    # The v2 hash is encoded as "<version>.<md5 llm + text>.<timestamp>"
    # We do not need to regenerate if:
    # - the hash version and md5 are the same (the data is unchanged)
    # - the timestamp of the last reindex is later than this one.
    #   Indexing happens in threads, and involves API calls, so there is a nonzero chance
    #   that model changes get interleaved.
    private def _hybrid_search_hash_changed(new_text)
      now = self.db.fetch("SELECT now() AS now").first.fetch(:now)
      # Get the timestamp as a microsecond integer
      now_tsint = (now.to_i * (10**6)) + now.usec
      content_digest = Digest::MD5.new
      content_digest.update(SequelHybridSearch.embedding_generator.model_name)
      content_digest.update(new_text)
      new_hashed_content = content_digest.hexdigest
      old_hash = self.send(self.model.hybrid_search_hash_column)
      new_hash_parts = [HASH_VERSION, new_hashed_content, now_tsint]
      # If the old hash is a different version, we know we'll need to update.
      return new_hash_parts unless old_hash&.start_with?("#{HASH_VERSION}.")
      # Parse the old hash. If the content hasn't changed, we don't need to rebuild.
      _old_version, old_hashed_content, _old_timestamp = old_hash.split(".")
      return nil if old_hashed_content == new_hashed_content
      # We may need to rebuild, do the conditional update.
      return new_hash_parts
    end

    # For the search/text content, only include tokens which come after ':' if present.
    # These fields are the dynamically determined ones so are the only ones
    # relevant for keyword searches.
    private def _hybrid_search_text_to_storage(text)
      # Always include the model name so things like 'Users named Tim' will find all users (and rank Tim more highly),
      # while 'Tim' will only find users with the literal 'Tim'.
      content = [self.model.table_name.to_s.gsub(/[^a-zA-Z]/, " ")]
      text.lines.each do |li|
        idx = li.index(":")
        next if idx.nil?
        s = li[(idx + 1)..].strip
        next if s.blank?
        # Ignore symbol-only lines. See https://www.ascii-code.com/ for a table;
        # " -/" catches all everything from codes 32 to 47, for example.
        # Rubocop has a bug here, %r{} regex form cannot be used due to the backtick, so turn it off.
        next if s.match?(/^[ -\/:-@\[-`{-~]+$/) # rubocop:disable Style/RegexpLiteral
        content << s
      end
      return content.join("\n")
    end
  end
end

# Patch pgvector to handle nil column values.
module Pgvector
  class << self
    alias original_encode encode
    def encode(data)
      return nil if data.nil?
      return original_encode(data)
    end

    alias original_decode decode
    def decode(string)
      return nil if string.nil?
      return original_decode(string)
    end
  end
end
