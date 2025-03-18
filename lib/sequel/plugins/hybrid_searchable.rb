# frozen_string_literal: true

require "sequel/sequel_hybrid_searchable"
require "pgvector"

module Sequel::Plugins::HybridSearchable
  DEFAULT_OPTIONS = {
    content_column: :search_content,
    vector_column: :search_embedding,
    hash_column: :search_hash,
    tsvector_column: :search_tsv,
  }.freeze

  def self.apply(*); end

  def self.configure(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    model.hybrid_search_content_column = opts[:content_column]
    model.hybrid_search_vector_column = opts[:vector_column]
    model.hybrid_search_hash_column = opts[:hash_column]
    model.hybrid_search_tsvector_column = opts[:tsvector_column]
    SequelHybridSearchable.searchable_models << model
    model.plugin :pgvector, model.hybrid_search_vector_column
  end

  module DatasetMethods
    def hybrid_search(q, distance: "euclidean")
      embedding = SequelHybridSearchable.embedding_generator.get_embedding(q)
      return self.nearest_neighbors(self.model.hybrid_search_vector_column, Pgvector.encode(embedding), distance:)
    end
  end

  module ClassMethods
    attr_accessor :hybrid_search_content_column,
                  :hybrid_search_vector_column,
                  :hybrid_search_hash_column,
                  :hybrid_search_tsvector_column

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
      self.this.update(
        self.model.hybrid_search_content_column => text,
        self.model.hybrid_search_vector_column => Pgvector.encode(em),
        self.model.hybrid_search_hash_column => new_hash,
      )
    end

    def hybrid_search_text = raise NotImplementedError
  end
end
