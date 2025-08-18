# frozen_string_literal: true

require "rack/remote_ip"
require "grape"

require "suma/api"
require "suma/i18n"

class Suma::API::Meta < Suma::API::V1
  include Suma::API::Entities

  resource :meta do
    get :supported_geographies do
      use_http_expires_caching 2.days
      countries = Suma::SupportedGeography.order(:label).where(type: "country").all
      country_ids = countries.map(&:id)
      provinces = Suma::SupportedGeography.order(:label).where(type: "province").all
      result = {}
      result[:countries] = countries.map do |c|
        {label: c.label, value: c.value}
      end
      result[:provinces] = provinces.map do |p|
        {label: p.label, value: p.value, country_idx: country_ids.index(p.parent_id)}
      end
      present result
    end

    get :supported_currencies do
      use_http_expires_caching 2.days
      cur = Suma::SupportedCurrency.dataset.order(:ordinal).all
      raise Suma::InvalidPrecondition, "no currencies set up, app is busted" if cur.empty?
      present_collection cur, with: CurrencyEntity
    end

    get :supported_locales do
      use_http_expires_caching 2.days
      present_collection Suma::I18n::SUPPORTED_LOCALES.values, with: LocaleEntity
    end

    get :supported_payment_methods do
      use_http_expires_caching 2.days
      present_collection Suma::Payment.supported_methods
    end

    # Proxy a call to an IP geolocation service.
    # We cannot safely call other origins from the browser, so do it from our API.
    get :geolocate_ip do
      # Do not cache this endpoint.
      # The IP can change and is an implicit dependency of the call.
      remote_ip = env["rack.remote_ip"].to_s
      got = Suma::Http.get("http://ip-api.com/json/#{remote_ip}", logger: self.logger)
      r = got.parsed_response
      resp = {lat: r.fetch("lat"), lng: r.fetch("lon")}
      present(resp)
    end

    get :supported_organizations do
      use_http_expires_caching 30.minutes
      ds = Suma::Organization.
        where { ordinal >= 0.0 }.
        order(Sequel.desc(:ordinal), :name)
      orgs = ds.select_map(:name).map { |name| {name:} }
      present_collection orgs
    end

    resource :static_strings do
      helpers do
        def ifmodsince
          t = env["HTTP_IF_MODIFIED_SINCE"]
          return Time.at(0) unless t
          return Time.httpdate(t)
        rescue ArgumentError
          return Time.at(0)
        end
      end

      route_param :locale do
        get :stripe do
          use_http_expires_caching 24.hours
          text_for_key = Suma::I18n::StaticString.
            namespace_locale_dataset(namespace: "strings", locale: params[:locale]).
            where(key: Suma::Stripe::ERRORS_FOR_CODES.values.map { |c| "errors.#{c}" }).
            select(:key, params[:locale]).
            naked.
            select_map([:key, params[:locale].to_sym]).
            to_h
          result = {
            errors: Suma::Stripe::ERRORS_FOR_CODES.filter_map do |stripe_code, strings_code|
              mapped = text_for_key["errors.#{strings_code}"]
              mapped ? [stripe_code, ["s", mapped]] : nil
            end.to_h,
          }
          present(result)
        end

        route_param :namespace do
          get do
            # The frontend includes its build SHA to make sure we get a new file when we ship a new frontend.
            use_http_expires_caching 24.hours
            # We are using sendfile without a file, and need to be careful about assumptions we make
            # around last-modified caching.
            # - Grape sendfile may or may not set last-modified; we may as well set it ourselves.
            #   I haven't debugged with how it's being calculated but not eventually sent.
            # - Rack::ConditionalGet still does too much work; we replicate the behavior here instead.
            f = Suma::I18n::StaticStringRebuilder.instance.
              path_for(namespace: params[:namespace], locale: params[:locale])
            begin
              mtime = f.mtime
            rescue Errno::ENOENT
              forbidden!
            end
            if ifmodsince > mtime
              status 304
              body nil
            else
              header "last-modified", mtime.httpdate
              sendfile f.to_s
            end
          end
        end
      end
    end
  end
end
