# frozen_string_literal: true

require "suma/admin_api"

class Suma::AdminAPI::Meta < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :meta do
    get :currencies do
      use_http_expires_caching 2.days
      check_admin_role_access!(:read, :admin_access)
      cur = Suma::SupportedCurrency.dataset.order(:ordinal).all
      present_collection cur, with: CurrencyEntity
    end

    get :geographies do
      use_http_expires_caching 2.days
      check_admin_role_access!(:read, :admin_access)
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
      check_admin_role_access!(:read, :admin_access)
      categories = Suma::Vendor::ServiceCategory.tsort_all
      present_collection categories, with: HierarchicalCategoryEntity
    end

    get :programs do
      check_admin_role_access!(:read, Suma::Program)
      ds = Suma::Program.dataset
      ds = ds.translation_join(:name, [:en])
      ds = ds.order(:name_en)
      present_collection ds, with: SlimProgramEntity
    end

    get :resource_access do
      use_http_expires_caching 12.hours
      check_admin_role_access!(:read, :admin_access)
      present Suma::AdminAPI::Access.as_json
    end

    resource :state_machines do
      route_param :name, type: Symbol do
        get do
          use_http_expires_caching 12.hours
          check_admin_role_access!(:read, :admin_access)
          sm = {
            organization_membership_verification_status: Suma::Organization::Membership::Verification.state_machine(:status),
          }[params[:name]]
          forbidden! unless sm
          state_names = sm.states.map(&:name)
          present({state_names:})
        end
      end
    end

    get :vendor_service_mobility_adapter_options do
      use_http_expires_caching 48.hours
      check_admin_role_access!(:read, :admin_access)
      present_collection Suma::Vendor::Service.mobility_adapter_setting_options
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
    expose :hierarchical_label, as: :label
  end

  class SlimProgramEntity < BaseEntity
    include Suma::AdminAPI::Entities
    include AutoExposeBase
    expose :name do |o|
      o.name.en
    end
  end
end
