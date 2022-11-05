# frozen_string_literal: true

require "appydays/loggable"
require "grape"

require "suma/service" unless defined?(Suma::Service)

class Suma::Service::Collection
  extend Suma::MethodUtilities

  singleton_attr_reader :collection_entity_cache
  @collection_entity_cache = {}

  attr_reader :current_page, :items, :page_count, :total_count, :last_page

  class BaseEntity < Suma::Service::Entities::Base
    expose :object do |_|
      "list"
    end
    expose :current_page
    expose :page_count
    expose :total_count
    expose :more?, as: :has_more
    # expose :items do |_|
    #   raise "this must be exposed by the subclass, like: `expose :items, with: MyEntity`"
    # end
  end

  def self.from_dataset(ds)
    if ds.respond_to?(:current_page)
      return self.new(
        ds.all,
        current_page: ds.current_page,
        page_count: ds.page_count,
        total_count: ds.pagination_record_count,
        last_page: ds.last_page?,
      )
    end
    return self.from_array(ds.all)
  end

  def self.from_array(array)
    return self.new(array, current_page: 1, page_count: 1, total_count: array.size, last_page: true)
  end

  def initialize(items, current_page:, page_count:, total_count:, last_page:)
    @items = items
    @current_page = current_page
    @page_count = page_count
    @last_page = last_page
    @total_count = total_count
  end

  def last_page?
    return @last_page
  end

  def more?
    return !@last_page
  end

  module Helpers
    def present_collection(collection, opts={})
      passed_entity = opts.delete(:with) || opts.delete(:using)
      # We can't use is_a? here, Grape entity is weird.
      if passed_entity&.ancestors&.include?(Suma::Service::Collection::BaseEntity)
        collection_entity = passed_entity
      else
        collection_entity = Suma::Service::Collection.collection_entity_cache[passed_entity]
        if collection_entity.nil?
          collection_entity = Class.new(Suma::Service::Collection::BaseEntity) do
            expose :items, using: passed_entity
          end
          Suma::Service::Collection.collection_entity_cache[passed_entity] = collection_entity
        end
      end
      opts[:with] = collection_entity

      wrapped =
        if collection.respond_to?(:dataset) || collection.is_a?(Sequel::Dataset)
          Suma::Service::Collection.from_dataset(collection)
        elsif collection.is_a?(Suma::Service::Collection)
          collection
        else
          Suma::Service::Collection.from_array(collection)
        end

      present wrapped, opts
    end
  end
end
