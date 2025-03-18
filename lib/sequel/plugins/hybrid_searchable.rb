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

    def hybrid_search(q, limit: 10, outer_limit_multiplier: 4)
      outer_limit = limit * outer_limit_multiplier
      query_embedding = SequelHybridSearchable.embedding_generator.get_embedding(q)
      pk = self.primary_key
      tbl = self.table_name
      vec_col = self.hybrid_search_vector_column
      content_col = self.hybrid_search_content_column
      # Based on https://github.com/pgvector/pgvector-python/blob/master/examples/hybrid_search/rrf.py
      sql = <<~SQL
        WITH semantic_search AS (
            SELECT #{pk} as id, RANK () OVER (ORDER BY #{vec_col} <=> ?) AS rank
            FROM #{tbl}
            ORDER BY #{vec_col} <=> ?
            LIMIT #{outer_limit}
        ),
        keyword_search AS (
            SELECT #{pk} as id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector(?, #{content_col}), query) DESC)
            FROM #{tbl}, plainto_tsquery(?, ?) query
            WHERE to_tsvector(?, #{content_col}) @@ query
            ORDER BY ts_rank_cd(to_tsvector(?, #{content_col}), query) DESC
            LIMIT #{outer_limit}
        )
        SELECT
            COALESCE(semantic_search.id, keyword_search.id) AS #{pk},
            COALESCE(1.0 / (? + semantic_search.rank), 0.0) +
              COALESCE(1.0 / (? + keyword_search.rank), 0.0) AS score
        FROM semantic_search
        FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
        ORDER BY score DESC
        LIMIT #{limit}
      SQL
      vec = Pgvector.encode(query_embedding)
      lang = self.hybrid_search_language
      k = 60
      args = [
        vec, vec,
        lang,
        lang, q,
        lang,
        lang,
        k,
        k,
      ]
      ds = self.db.fetch(sql, *args)
      ids = ds.all.map { |r| r[:id] }
      results = self.where(pk => ids).all
      results.sort_by! { |r| ids.find_index(r[pk]) }
      return results
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
      self.this.update(
        self.model.hybrid_search_content_column => text,
        self.model.hybrid_search_vector_column => Pgvector.encode(em),
        self.model.hybrid_search_hash_column => new_hash,
      )
    end

    def hybrid_search_text = raise NotImplementedError
  end
end
