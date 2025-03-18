# frozen_string_literal: true

require "sequel/sequel_vector_searchable"
require "pgvector"

module Sequel::Plugins::VectorSearchable
  DEFAULT_OPTIONS = {
    vector_column: :embedding,
    hash_column: :embedding_hash,
  }.freeze

  def self.apply(*); end

  def self.configure(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    model.vector_search_vector_column = opts[:vector_column]
    model.vector_search_hash_column = opts[:hash_column]
    SequelVectorSearchable.searchable_models << model
    model.plugin :pgvector, model.vector_search_vector_column
  end

  module DatasetMethods
    def vector_search(q, distance: "euclidean")
      embedding = SequelVectorSearchable.embedding_generator.get_embedding(q)
      return self.nearest_neighbors(self.model.vector_search_vector_column, Pgvector.encode(embedding), distance:)
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

    def vector_search_reindex_model(model_pk)
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
      if SequelVectorSearchable.indexing_mode == :async
        # We must refetch the model to index since it happens on another thread.
        SequelVectorSearchable.threadpool.post do
          self.model.vector_search_reindex_model(self.pk)
        end
      elsif SequelVectorSearchable.indexing_mode == :sync
        self.vector_search_reindex
      end
    end

    def vector_search_reindex
      text = self.vector_search_text
      new_hash = "#{SequelVectorSearchable.embedding_generator.model_name}-#{Digest::MD5.hexdigest(text)}"
      return if new_hash == self.send(self.model.vector_search_hash_column)
      em = SequelVectorSearchable.embedding_generator.get_embedding(text)
      self.this.update(
        self.model.vector_search_vector_column => Pgvector.encode(em),
        self.model.vector_search_hash_column => new_hash,
      )
    end

    def vector_search_text = raise NotImplementedError
  end
end
