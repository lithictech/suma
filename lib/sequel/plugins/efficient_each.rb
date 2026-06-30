# frozen_string_literal: true

module Sequel::Plugins::EfficientEach
  class UnknownAssociation < ArgumentError; end

  DEFAULT_OPTIONS = {
    page_size: 100,
  }.freeze

  class << self
    def configure(model, opts=DEFAULT_OPTIONS)
      opts = DEFAULT_OPTIONS.merge(opts)
      model.efficient_each_page_size = opts[:page_size]
    end
  end

  module ClassMethods
    attr_accessor :efficient_each_page_size

    def inherited(subclass)
      super
      [:efficient_each_page_size].each do |m|
        subclass.send("#{m}=", self.send(m))
      end
    end
  end

  module DatasetMethods
    # Call a block for each row in a dataset.
    # This is the same as paged_each or use_cursor.each, except that for each page,
    # rows are re-fetched using self.where(primary_key => [pks]).all to enable eager loading.
    #
    # @param page_size [Integer] Size of each page. Smaller uses less memory.
    # @param order [Symbol] Column to order by. Default to primary key.
    # @param yield_page [true,false] If true, yield the page to the block, rather than individual rows.
    #   Helpful when bulk processing.
    #
    # (Note that paged_each does not do eager loading, which makes enumerating model associations very slow)
    def each_cursor_page(page_size: nil, order: nil, yield_page: false, &)
      model = self.model
      page_size ||= model.efficient_each_page_size
      pk = model.primary_key
      order ||= pk
      Sequel::Plugins::EfficientEach.each_cursor_page(self, pk:, page_size:, yield_page:, order:, &)
    end
  end

  def self.each_cursor_page(dataset, pk:, page_size:, yield_page:, order: nil, &block)
    raise LocalJumpError unless block
    raise "dataset requires a use_cursor method, class may need `extension(:pagination)`" unless
      dataset.respond_to?(:use_cursor)
    order ||= pk
    current_chunk_pks = []
    order = [order] unless order.respond_to?(:to_ary)
    dataset.naked.select(pk).order(*order).use_cursor(rows_per_fetch: page_size, hold: true).each do |row|
      current_chunk_pks << row[pk]
      next if current_chunk_pks.length < page_size
      page = dataset.where(pk => current_chunk_pks).order(*order).all
      current_chunk_pks.clear
      yield_page ? yield(page) : page.each(&block)
    end
    remainder = dataset.where(pk => current_chunk_pks).order(*order).all
    yield_page && !remainder.empty? ? yield(remainder) : remainder.each(&block)
  end

  module InstanceMethods
    def efficient_each(association_name, &)
      return enum_for(:efficient_each, association_name) unless block_given?

      assoc = self.class.association_reflection(association_name)
      raise UnknownAssociation, "#{self.class.name} has no association :#{association_name}" if
        assoc.nil?
      loaded = self.associations[association_name]
      unless loaded.nil?
        loaded.each(&)
        return nil
      end
      dataset = self.send(assoc.fetch(:dataset_method))
      pagecount = 0
      prev_page = []
      dataset.each_cursor_page(yield_page: true) do |page|
        pagecount += 1
        prev_page = page
        page.each(&)
      end
      self.associations[association_name] = prev_page if pagecount < 2
      return nil
    end
  end
end
