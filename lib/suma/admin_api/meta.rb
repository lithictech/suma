# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::Meta < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :meta do
    get :currencies do
      use_http_expires_caching 2.days
      cur = Suma::SupportedCurrency.dataset.order(:ordinal).all
      present_collection cur, with: CurrencyEntity
    end

    get :geographies do
      use_http_expires_caching 2.days
      countries = Suma::SupportedGeography.order(:label).where(type: "country").all
      provinces = Suma::SupportedGeography.order(:label).where(type: "province").all
      result = {}
      result[:countries] = countries.map do |c|
        {label: c.label, value: c.value}
      end
      result[:provinces] = provinces.map do |p|
        {label: p.label, value: p.value, country: {label: p.parent.label, value: p.parent.value}}
      end
      present result
    end

    get :vendor_service_categories do
      sc = Suma::Vendor::ServiceCategory.dataset.order(:name).all
      present_collection sc, with: HierarchicalCategoryEntity
    end

    get :programs do
      ds = Suma::Program.dataset
      ds = ds.translation_join(:name, [:en])
      ds = ds.order(:name_en)
      present_collection ds, with: SlimProgramEntity
    end

    get :resource_access do
      use_http_expires_caching 12.hours
      present Suma::AdminAPI::Access.as_json
    end
  end

  class CurrencyEntity < BaseEntity
    expose :symbol
    expose :code
  end

  class HierarchicalCategoryEntity < BaseEntity
    expose :id
    expose :slug
    expose :name
    expose :full_label, as: :label
  end

  class SlimProgramEntity < BaseEntity
    expose :id
    expose :name do |o|
      o.name.en
    end
  end
end
