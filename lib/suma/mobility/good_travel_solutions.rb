# frozen_string_literal: true

# https://gtsapistg.developer.azure-api.net/apis
# # https://goodtravelsoftware.atlassian.net/servicedesk/customer/portal/2/article/1829044225
module Suma::Mobility::GoodTravelSolutions
  include Appydays::Configurable
  include Appydays::Loggable

  class AccessDetail < Suma::TypedStruct
    attr_accessor :scheme_key, :community_id, :vendor_name

    # @return [Suma::Vendor]
    def mobility_vendor
      return Suma.cached_get("gts_mobility_vendor_#{self.scheme_key}") do
        Suma::Vendor.find_or_create_or_find(name: self.vendor_name)
      end
    end

    # @return [Suma::Mobility::Gbfs::Client]
    def gbfs_client
      return Suma::Mobility::GoodTravelSolutions::GbfsClient.new(self)
    end
  end

  class << self
    attr_accessor :api_host

    # @!attribute access_details
    # @return [Array<AccessDetail>]
    attr_accessor :access_details
  end

  configurable(:gts) do
    setting :api_host, "http://gtsapi.localhost"
    setting :access_details_json, "[]"

    after_configured do
      self.access_details = JSON.parse(self.access_details_json).map do |j|
        AccessDetail.new(**j.symbolize_keys)
      end
    end
  end

  class GbfsClient < Suma::Mobility::Gbfs::Client
    # @!attribute ad
    # @return [AccessDetail]
    attr_accessor :ad

    # @param ad [AccessDetail]
    def initialize(ad)
      super()
      @ad = ad
    end

    protected def post_to(tail, body)
      b = {schemeKey: self.ad.scheme_key, community: self.ad.community_id}
      b.merge!(body)
      cls = Suma::Mobility::GoodTravelSolutions
      response = Suma::Http.post("#{cls.api_host}#{tail}", b, logger: cls.logger)
      return response.parsed_response
    end

    protected def vehicle_type_id(vtstr) = "gts-#{vtstr}"

    protected def format_time(t, tz)
      in_tz = t.in_time_zone(tz)
      return in_tz.strftime("%Y-%m-%d %H:%M:%S")
    end

    def fetch_geofencing_zones = {"data" => {"geofencing_zones" => {}}}

    def fetch_vehicle_types
      return self._fetch_gts_vehicle_types.map do |vt|
        {
          vehicle_type_id: self.vehicle_type_id(vt.fetch("key")),
          form_factor: "car",
          propulsion_type: "electric",
          name: vt.fetch("label"),
          max_range_meters: 99_999,
        }
      end
    end

    def fetch_free_bike_status
      bikes = []
      self._fetch_gts_stations.each do |station|
        station_id = station.fetch("id")
        self._fetch_gts_models.each do |model|
          model_id = model.fetch("id")
          body = self.post_to(
            "/v2/explore/available-slots",
            {
              slotSize: 60,
              model: model_id,
              station: station_id,
              **self.reservation_window(station),
            },
          )
          # If there is no array of availability, do not show any vehicles for this station/model
          next if body.empty?
          # Add one vehicle representing this station/model
          bikes << {
            bike_id: "gts-#{self.ad.community_id}-#{station_id}-#{model_id}",
            last_reported: Time.now.to_i,
            lat: station.fetch("latitude"),
            lon: station.fetch("longitude"),
            is_reserved: false,
            is_disabled: false,
            vehicle_type_id: self.vehicle_type_id(model.fetch("vehicleType")),
          }
        end
      end
      return {"data" => {"bikes" => bikes}}
    end

    # https://gtsapistg.developer.azure-api.net/api-details#api=sharecarapi-v2&operation=post-explore-stations
    def _fetch_gts_stations
      @stations ||= self.post_to("/v2/explore/stations/available",
                                 {**self.reservation_window(start_key: :pickUpDatetime, end_key: :dropOffDatetime)},)
      return @stations.fetch("_embedded").fetch("stations")
    end

    # https://gtsapistg.developer.azure-api.net/api-details#api=sharecarapi-v2&operation=post-explore-models
    def _fetch_gts_models
      @models ||= self.post_to("/v2/explore/models", {})
      return @models.fetch("_embedded").fetch("models")
    end

    # https://gtsapistg.developer.azure-api.net/api-details#api=sharecarapi-v2&operation=post-explore-vehicle-types
    def _fetch_gts_vehicle_types
      @vehicle_types ||= self.post_to("/v2/explore/vehicle-types", {})
      return @vehicle_types.fetch("_embedded").fetch("vehicleTypes")
    end

    protected def reservation_window(station=nil, start_key: :startTime, end_key: :endTime)
      # In places we don't have a station, use the max continental US timezones.
      # This may need to be adjusted in the future but it's a limitation of the GTS API
      # (the endpoint to get stations, uses timestamps relative to stations).
      return {
        start_key => self.format_time(Time.now + 24.hours, station&.fetch("timezone") || "America/Los_Angeles"),
        end_key => self.format_time(Time.now + 48.hours, station&.fetch("timezone") || "America/New_York"),
      }
    end
  end
end
