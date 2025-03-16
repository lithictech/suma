# frozen_string_literal: true

require "sequel/sequel_vector_searchable"

module Sequel::Plugins::VectorSearchable
  DEFAULT_OPTIONS = {
    vector_column: :embedding,
    hash_column: :embedding,
  }.freeze

  # def self.apply(model, *)
  # end

  def self.configure(model, opts=DEFAULT_OPTIONS)
    opts = DEFAULT_OPTIONS.merge(opts)
    model.vector_search_vector_column = opts[:vector_column]
    model.vector_search_hash_column = opts[:hash_column]
    SequelVectorSearchable.searchable_models << model
  end

  module DatasetMethods
    def vector_search(q, opts={})
      full_opts = self.model.vector_search_options.merge(tsvector: true).merge(opts)
      return self.full_vector_search(self.model.vector_search_column, q, **full_opts)
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
      if SequelVectorSearchable.index_mode == :async
        # We must refetch the model to index since it happens on another thread.
        SequelVectorSearchable.threadpool.post do
          self.model.vector_search_reindex_model(self.pk)
        end

      elsif SequelVectorSearchable.index_mode == :sync
        self.vector_search_reindex
      end
    end

    def vector_search_reindex
      # got_terms = self.vector_search_terms
      # return if got_terms.empty?
      # terms = got_terms.flat_map { |t| _vector_search_term_to_col_and_rank(t) }
      # exprs = terms.filter_map do |(col, rank)|
      #   col = Sequel.function(:coalesce, col, "")
      #   expr = Sequel.function(:to_tsvector, self.model.vector_search_language, col)
      #   expr = Sequel.function(:setweight, expr, rank) if rank
      #   expr
      # end
      # full_expr = Sequel.join(exprs)
      # self.this.update(self.model.vector_search_column => full_expr)
    end

    def vector_search_text = raise NotImplementedError
  end
end
