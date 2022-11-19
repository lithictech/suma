# frozen_string_literal: true

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
  end
end
