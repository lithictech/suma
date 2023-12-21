# frozen_string_literal: true

require "suma/mobility/gbfs/component_sync"

class Suma::Mobility::Gbfs::MdpModelsAvailable < Suma::Mobility::Gbfs::ComponentSync
  def model = Suma::Mobility::Vehicle

  def before_sync(client)
    @vehicle_types = client.fetch_mdp_vehicle_types.dig("_embedded", "vehicleTypes").map { |vt| vt["label"].downcase }
    @stations = client.fetch_mdp_stations_available(vehicle_types: @vehicle_types).dig("_embedded", "stations")
    @client = client
  end

  def yield_rows(vendor_service)
    stations = @stations
    vehicle_types = @vehicle_types
    client = @client
    stations.each do |station|
      models = client.fetch_mdp_station_models_available(station: station["id"], vehicle_types:).
        dig("_embedded", "models")
      models.each do |model|
        row = {
          lat: station["latitude"],
          lng: station["longitude"],
          vehicle_id: model["id"],
          vehicle_name: model["fullName"],
          vehicle_type: model["vehicleType"],
          vendor_service_id: vendor_service.id,
        }
        yield row
      end
    end
  end
end
