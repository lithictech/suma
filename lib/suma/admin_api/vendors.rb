# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Vendors < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :vendors do
    params do
      use :pagination
      use :ordering, model: Suma::Vendor
      use :searchable
    end
    get do
      ds = Suma::Vendor.dataset
      if (name_like = search_param_to_sql(params, :name))
        slug_like = search_param_to_sql(params, :slug)
        ds = ds.where(name_like | slug_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: VendorEntity
    end

    params do
      requires :name, type: String
    end
    post :create do
      adminerror!(403, "Vendor #{params[:name]} already exists") if Suma::Vendor.find(name: params[:name])
      v = Suma::Vendor.create(name: params[:name])
      created_resource_headers(v.id, v.admin_link)
      status 200
      present v, with: Suma::AdminAPI::Entities::VendorEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup
          (v = Suma::Vendor[params[:id]]) or forbidden!
          return v
        end
      end

      get do
        v = lookup
        present v, with: DetailedVendorEntity
      end
    end
  end

  class DetailedVendorEntity < VendorEntity
    include Suma::AdminAPI::Entities
    expose :slug
    expose :services, with: VendorServiceEntity
    expose :products, with: ProductEntity
  end
end