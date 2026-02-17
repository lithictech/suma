# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::ShortUrls < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  class ShortenedUrlEntity < BaseEntity
    expose :id
    expose :short_id
    expose :short_url
    expose :long_url
    expose :inserted_at
    expose :admin_link do |sh|
      Suma::UrlShortener.admin_link(sh.id)
    end
  end

  class ShortenedUrlRowEntity < BaseEntity
    expose :id
    expose :short_id
    expose :url, as: :long_url
    expose :short_url do |r|
      Suma::UrlShortener.shortener.short_url_from_id(r.fetch(:short_id))
    end
    expose :inserted_at
    expose :admin_link do |r|
      Suma::UrlShortener.admin_link(r[:id])
    end
  end

  resource :short_urls do
    params do
      use :pagination
      use :ordering, default: :inserted_at, values: [:id, :short_id, :url, :inserted_at]
      use :searchable
    end
    get do
      check_admin_role_access!(:read, Suma::Member::RoleAccess::MARKETING_SMS)
      ds = Suma::UrlShortener.shortener.dataset
      if (search = params[:search]).present?
        srch = "%#{search}%"
        ds = ds.where(
          Sequel[:short_id].ilike(srch) |
          Sequel[:url].ilike(srch),
        )
      end
      ds = order(ds, params, disambiguator: :short_id)
      ds = paginate(ds, params)
      present_collection ds, with: ShortenedUrlRowEntity
    end

    params do
      optional :long_url, type: String, allow_blank: true
    end
    post :create do
      check_admin_role_access!(:write, Suma::Member::RoleAccess::MARKETING_SMS)
      sh = Suma::UrlShortener.shortener.shorten(params[:long_url] || "")
      created_resource_headers(sh.id, Suma::UrlShortener.admin_link(sh.id))
      status 200
      present sh, with: ShortenedUrlEntity
    end

    route_param :id, type: Integer do
      get do
        check_admin_role_access!(:write, Suma::Member::RoleAccess::MARKETING_SMS)
        (row = Suma::UrlShortener.shortener.dataset[id: params[:id]]) or forbidden!
        sh = Suma::UrlShortener.shortener.shortened_from_row(row)
        status 200
        present sh, with: ShortenedUrlEntity
      end

      params do
        optional :short_id, type: String, allow_blank: true
        optional :long_url, type: String
      end
      post do
        check_admin_role_access!(:write, Suma::Member::RoleAccess::MARKETING_SMS)
        sh = Suma::UrlShortener.shortener.update(params[:id], short_id: params[:short_id], url: params[:long_url])
        created_resource_headers(sh.id, Suma::UrlShortener.admin_link(sh.id))
        status 200
        present sh, with: ShortenedUrlEntity
      end
    end
  end
end
