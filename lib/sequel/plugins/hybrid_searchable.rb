# frozen_string_literal: true

require "sequel/sequel_hybrid_searchable"
require "pgvector"

module Sequel::Plugins::HybridSearchable
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
    SequelHybridSearchable.searchable_models << model
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
    # Pagination can be used with offset/limit.
    # The +outer_limit_multiplier+ is used for the 'inner' semantic and keyword queries;
    # that is, they will rank +limit*outer_limit_multiplier+ results,
    # before limiting the final result.
    #
    # Note that calculating later pages may get very slow,
    # even moreso than normal offset/limit pagination,
    # which has this problem (since skipped rows still need to be ranked).
    # To avoid this, you can use cursor-based pagination by filtering the dataset,
    # like `ds.where { id > last_result_id }.hybrid_search(...)`.
    def hybrid_search(q, limit:, outer_limit_multiplier: 4, offset: 0)
      outer_limit = limit * outer_limit_multiplier
      outer_limit += offset * outer_limit_multiplier
      query_embedding = SequelHybridSearchable.embedding_generator.get_embedding(q)
      pk = self.model.primary_key
      tbl = self.model.table_name
      vec_col = self.model.hybrid_search_vector_column
      content_col = self.model.hybrid_search_content_column
      q = q.strip
      # Based on https://github.com/pgvector/pgvector-python/blob/master/examples/hybrid_search/rrf.py
      kw_sql = if q.blank? || q == "*"
                 <<~SQL
                   SELECT #{pk} as id, 0 as rank
                   FROM #{tbl}
                   LIMIT #{limit} -- ? ? ? ? ?
                 SQL
      else
        <<~SQL
          SELECT #{pk} as id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector(?, #{content_col}), query) DESC)
          FROM #{tbl}, websearch_to_tsquery(?, ?) query
          WHERE to_tsvector(?, #{content_col}) @@ query
          ORDER BY ts_rank_cd(to_tsvector(?, #{content_col}), query) DESC
          LIMIT #{outer_limit}
        SQL
      end
      sql = <<~SQL
        WITH semantic_search AS (
            SELECT #{pk} as id, RANK () OVER (ORDER BY #{vec_col} <=> ?) AS rank
            FROM #{tbl}
            ORDER BY #{vec_col} <=> ?
            LIMIT #{outer_limit}
        ),
        keyword_search AS (
            #{kw_sql}
        )
        SELECT
            COALESCE(semantic_search.id, keyword_search.id) AS #{pk},
            COALESCE(1.0 / (? + semantic_search.rank), 0.0) +
              COALESCE(1.0 / (? + keyword_search.rank), 0.0) AS score
        FROM keyword_search
        JOIN semantic_search ON semantic_search.id = keyword_search.id
        ORDER BY score DESC
        LIMIT #{limit}
        OFFSET #{offset}
      SQL
      vec = Pgvector.encode(query_embedding)
      lang = self.model.hybrid_search_language
      # Queries look like "users named Tim who were created in the last 5 days".
      # We need to use an OR against all words (rather than AND/FOLLOWED BY),
      # so that relevant terms like 'Tim' are matched, but irrelevant ones like 'days' are not.
      # This depends on only using as tsvector the unique/dynamic content for each row's search text,
      # so 'Tim' is present for rows with the name 'Tim'.
      processed_query = q.gsub(" ", " OR ")
      k = 60
      args = [
        vec, vec,
        lang,
        lang, processed_query,
        lang,
        lang,
        k,
        k,
      ]
      search_ds = self.db.fetch(sql, *args)
      # We could use a CTE but let's do this for now instead.
      search_ids = search_ds.select_map(pk)
      return self.model.dataset.where(pk => []) if search_ids.empty?
      model_ds = self.model.where(pk => search_ids).
        order(Sequel.function(:ARRAY_POSITION, Sequel.pg_array(search_ids), pk))
      return model_ds
    end
  end

  module ClassMethods
    attr_accessor :hybrid_search_content_column,
                  :hybrid_search_vector_column,
                  :hybrid_search_hash_column,
                  :hybrid_search_language

    def hybrid_search_reindex_all
      did = 0
      self.dataset.paged_each do |m|
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
      if SequelHybridSearchable.indexing_mode == :async
        # We must refetch the model to index since it happens on another thread.
        SequelHybridSearchable.threadpool.post do
          self.model.hybrid_search_reindex_model(self.pk)
        end
      elsif SequelHybridSearchable.indexing_mode == :sync
        self.hybrid_search_reindex
      end
    end

    def hybrid_search_reindex
      text = self.hybrid_search_text
      new_hash = "#{SequelHybridSearchable.embedding_generator.model_name}-#{Digest::MD5.hexdigest(text)}"
      return if new_hash == self.send(self.model.hybrid_search_hash_column)
      em = SequelHybridSearchable.embedding_generator.get_embedding(text)
      content = self._hybrid_search_text_to_storage(text)
      self.this.update(
        self.model.hybrid_search_content_column => content,
        self.model.hybrid_search_vector_column => Pgvector.encode(em),
        self.model.hybrid_search_hash_column => new_hash,
      )
    end

    def hybrid_search_text = raise NotImplementedError

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
