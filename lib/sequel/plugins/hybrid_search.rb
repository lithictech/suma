# frozen_string_literal: true

require "sequel/sequel_hybrid_search"
require "pgvector"

module Sequel::Plugins::HybridSearch
  DEFAULT_OPTIONS = {
    content_column: :search_content,
    vector_column: :search_embedding,
    hash_column: :search_hash,
    language: "english",
  }.freeze

  def self.apply(*); end

  def self.configure(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    model.hybrid_search_content_column = opts[:content_column]
    model.hybrid_search_vector_column = opts[:vector_column]
    model.hybrid_search_hash_column = opts[:hash_column]
    model.hybrid_search_language = opts[:language]
    SequelHybridSearch.searchable_models << model
    model.plugin :pgvector, model.hybrid_search_vector_column
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
      query_embedding = SequelHybridSearch.embedding_generator.get_embedding(q)
      pk = self.model.primary_key
      tbl = self.model.table_name
      vec_col = self.model.hybrid_search_vector_column
      content_col = self.model.hybrid_search_content_column
      q = q.strip
      vec = Pgvector.encode(query_embedding)
      lang = self.model.hybrid_search_language
      # Match certain queries against all rows, requires an OR 1=1 on the filter
      matchall = q.blank? || q == "*" ? " OR 1=1" : ""
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
      matches_tsquery = Sequel.lit("to_tsvector(?, #{content_col}) @@ query#{matchall}", lang)

      # Rank text-filtered rows based on their text match.
      kw_search = self.model.
        from(tbl, table_and_tsquery).
        where(matches_tsquery).
        select(
          Sequel[pk].as(:id),
          Sequel.function(:rank).
            over(order: Sequel.lit("ts_rank_cd(to_tsvector(?, #{content_col}), query) DESC", lang)).
            as(:rank),
        )

      # Now for semantic search. We still need to do the keyword matching,
      # so we only rank rows that are possible search candidates.
      semantic_search = self.model.
        from(tbl, table_and_tsquery).
        where(matches_tsquery).
        select(
          Sequel[pk].as(:id),
          Sequel.function(:rank).
            over(order: Sequel.lit("#{vec_col} <=> ?", vec)).
            as(:rank),
        )

      # Now join on our two queries, and order it based on their combined ranking.
      # This is RFF, as well explained here:
      # https://jkatz05.com/post/postgres/hybrid-search-postgres-pgvector/
      # Not sure what this value is
      rff_k = 60
      rank_order = Sequel.lit(
        "COALESCE(1.0 / (#{rff_k} + semantic_search.rank), 0.0) + " \
        "COALESCE(1.0 / (#{rff_k} + kw_search.rank), 0.0) DESC",
      )
      ds = self.model.
        join(kw_search.as(:kw_search), id: pk).
        join(semantic_search.as(:semantic_search), id: pk).
        order(rank_order)
      return ds
    end
  end

  module ClassMethods
    attr_accessor :hybrid_search_content_column,
                  :hybrid_search_vector_column,
                  :hybrid_search_hash_column,
                  :hybrid_search_language

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
        # We must refetch the model to index since it happens on another thread.
        SequelHybridSearch.threadpool.post do
          self.model.hybrid_search_reindex_model(self.pk)
        end
      elsif SequelHybridSearch.indexing_mode == :sync
        self.hybrid_search_reindex
      end
    end

    def hybrid_search_reindex
      text = self.hybrid_search_text
      new_hash = "#{SequelHybridSearch.embedding_generator.model_name}-#{Digest::MD5.hexdigest(text)}"
      return if new_hash == self.send(self.model.hybrid_search_hash_column)
      em = SequelHybridSearch.embedding_generator.get_embedding(text)
      content = self._hybrid_search_text_to_storage(text)
      self.this.update(
        self.model.hybrid_search_content_column => content,
        self.model.hybrid_search_vector_column => Pgvector.encode(em),
        self.model.hybrid_search_hash_column => new_hash,
      )
    end

    # For the search/text content, only include tokens which come after ':' if present.
    # These fields are the dynamically determined ones so are the only ones
    # relevant for keyword searches.
    def _hybrid_search_text_to_storage(text)
      # Always include the model name so things like 'Users named Tim' will find all users (and rank Tim more highly),
      # while 'Tim' will only find users with the literal 'Tim'.
      content = [self.model.table_name.to_s.gsub(/[^a-zA-Z]/, " ")]
      text.lines.each do |li|
        idx = li.index(":")
        next nil if idx.nil?
        s = li[idx + 1..].strip
        next if s.blank?
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
