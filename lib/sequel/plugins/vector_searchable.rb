# frozen_string_literal: true

require "sequel/sequel_vector_searchable"
require "pgvector"

module Sequel::Plugins::VectorSearchable
  DEFAULT_OPTIONS = {
    vector_column: :embeddings,
    hash_column: :embeddings_hash,
  }.freeze

  def self.apply(*)
    # SequelVectorSearchable::Embeddings.setup
  end

  def self.configure(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    model.vector_search_vector_column = opts[:vector_column]
    model.vector_search_hash_column = opts[:hash_column]
    SequelVectorSearchable.searchable_models << model
    model.plugin :pgvector, model.vector_search_vector_column
  end

  module DatasetMethods
    def vector_search(q, distance: "euclidean")
      embeddings = SequelVectorSearchable::Embeddings.get(q)
      return self.nearest_neighbors(self.model.vector_search_vector_column, Pgvector.encode(embeddings), distance:)
    end
  end

  module ClassMethods
    attr_accessor :vector_search_vector_column, :vector_search_hash_column

    def vector_search_reindex_all
      did = 0
      self.dataset.paged_each do |m|
        m.vector_search_reindex
        did += 1
      end
      return did
    end

    def vector_search_remodel(model_pk)
      m = self.with_pk!(model_pk)
      m.vector_search_reindex
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
      if SequelVectorSearchable::Indexing.mode == :async
        # Setup must always happen in the main thread
        SequelVectorSearchable::Embeddings.setup
        # We must refetch the model to index since it happens on another thread.
        SequelVectorSearchable::Indexing.threadpool.post do
          self.model.vector_search_remodel(self.pk)
        end

      elsif SequelVectorSearchable::Indexing.mode == :sync
        self.vector_search_reindex
      end
    end

    def vector_search_reindex
      em = SequelVectorSearchable::Embeddings.get(self.vector_search_text)
      self.this.update(self.model.vector_search_vector_column => Pgvector.encode(em))
    end

    def vector_search_text = raise NotImplementedError
  end
end
