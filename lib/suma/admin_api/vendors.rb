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
  end
end
