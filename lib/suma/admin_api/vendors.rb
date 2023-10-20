# frozen_string_literal: true

require "grape"
require "suma/admin_api"

class Suma::AdminAPI::Vendors < Suma::AdminAPI::V1
  resource :vendors do
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
