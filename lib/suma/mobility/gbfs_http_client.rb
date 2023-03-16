# frozen_string_literal: true

class Suma::Mobility::GbfsHttpClient
  attr_reader :api_host, :api_key

  def initialize(api_host:, api_key:)
    @api_host = api_host
    @api_key = api_key
  end

  def fetch_geofencing_zones
    response = Suma::Http.get(
      self.api_host.to_s + "/geofencing_zones.json",
      headers: {"Authorization" => "Bearer #{self.api_key}"},
    )
    return response.parsed_response
  end
end
