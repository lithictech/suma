# frozen_string_literal: true

require "grape"

require "suma/api"

class Suma::API::Meta < Suma::API::V1
  resource :meta do
    get :supported_geographies do
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
      cur = Suma::SupportedCurrency.dataset.order(:ordinal).all
      raise Suma::InvalidPrecondition, "no currencies set up, app is busted" if cur.empty?
      present_collection cur, with: Suma::API::CurrencyEntity
    end
  end
end
