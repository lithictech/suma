# frozen_string_literal: true

require "grape"

require "suma/api"

class Suma::API::Mobility < Suma::API::V1
  include Suma::Service::Types
  include Suma::API::Entities

  resource :mobility do
    desc "Return all mobility vehicles fitting the requested parameters."
    params do
      requires :sw, type: Array[BigDecimal], coerce_with: DecimalLocation
      requires :ne, type: Array[BigDecimal], coerce_with: DecimalLocation
      optional :types, type: Array[String], coerce_with: CommaSepArray, values: ["ebike", "escooter"]
    end
    get :map do
      me = current_member
      min_lat, min_lng = params[:sw]
      max_lat, max_lng = params[:ne]
      ds = Suma::Mobility::Vehicle.search(min_lat:, min_lng:, max_lat:, max_lng:)
      ds = ds.where(vehicle_type: params[:types]) if params.key?(:types)
      vendor_services = Suma::Vendor::Service.dataset.
        mobility.
        eligible_to(me, as_of: current_time).
        available_at(current_time)
      ds = ds.where(vendor_service: vendor_services)
      ds = ds.order(:id)
      vnd_services = []
      map_obj = {}
      # If a vehicle's identity is in this hash, we need to apply a disambiguator to it.
      # If the value of that hash is not nil, we assume that is the first occurance of the
      # duplicate identity vehicle and its hash, so the hash needs a disambiguator applied.
      # If the value is nil, we assume it's been applied.
      seen_identities_and_initial_vehicle_hashes = {}
      ds.all.each do |vehicle|
        if (vnd_svc_idx = vnd_services.find_index { |vs| vs.id === vehicle.vendor_service_id }).nil?
          vnd_svc_idx = vnd_services.length
          vnd_services << vehicle.vendor_service
        end
        vhash = {
          c: vehicle.to_api_location,
          p: vnd_svc_idx,
        }
        videntity = vehicle.api_identity
        if seen_identities_and_initial_vehicle_hashes.key?(videntity)
          vhash[:d] = vehicle.vehicle_id
          if (seen_tuple = seen_identities_and_initial_vehicle_hashes[videntity])
            seen_vehicle, seen_vhash = seen_tuple
            seen_vhash[:d] = seen_vehicle.vehicle_id
            seen_identities_and_initial_vehicle_hashes[videntity] = nil
          end
        else
          seen_identities_and_initial_vehicle_hashes[videntity] = [vehicle, vhash]
        end
        arr = map_obj[vehicle.vehicle_type.to_sym] ||= []
        arr << vhash
      end
      Suma::Mobility.offset_disambiguated_vehicles(map_obj)
      map_obj[:providers] = vnd_services
      present map_obj, with: MobilityMapEntity
    end

    desc "Return restrictions and other map features."
    params do
      requires :sw, type: Array[BigDecimal], coerce_with: DecimalLocation
      requires :ne, type: Array[BigDecimal], coerce_with: DecimalLocation
    end
    get :map_features do
      current_member
      min_lat, min_lng = params[:sw]
      max_lat, max_lng = params[:ne]
      ds = Suma::Mobility::RestrictedArea.intersecting(ne: [max_lat, max_lng], sw: [min_lat, min_lng])
      ds = ds.order(:id)
      result = {restrictions: ds.all}
      present result, with: MobilityMapFeaturesEntity
    end

    params do
      requires :loc, type: Array[Integer], coerce_with: IntegerLocation
      requires :provider_id, type: Integer
      requires :type, type: String, values: ["ebike", "escooter"]
      optional :disambiguator, type: String
    end
    get :vehicle do
      member = current_member
      matches = Suma::Mobility::Vehicle.where(
        lat_int: params[:loc][0],
        lng_int: params[:loc][1],
        vendor_service_id: params[:provider_id],
        vehicle_type: params[:type],
      ).all
      merror!(403, "No vehicle matching criteria was found", code: "vehicle_not_found") if matches.empty?
      if matches.length > 1
        disambig = params[:disambiguator]
        merror!(400, "Multiple vehicles found. Disambiguation required.", code: "disambiguation_required") if
          disambig.blank?
        vehicle = matches.find { |v| v.vehicle_id == disambig }
        merror!(403, "No disambiguated vehicle matching criteria was found", code: "vehicle_not_found") if vehicle.nil?
      else
        vehicle = matches[0]
      end
      present vehicle, with: MobilityVehicleEntity, member:, request:
    end

    params do
      requires :provider_id, type: Integer
      requires :vehicle_id, type: String
      requires :rate_id, type: Integer
    end
    post :begin_trip do
      member = current_member
      vehicle = Suma::Mobility::Vehicle[
        vendor_service_id: params[:provider_id],
        vehicle_id: params[:vehicle_id],
      ]
      merror!(403, "Vehicle does not exist", code: "vehicle_not_found") if vehicle.nil?
      check_eligibility!(vehicle.vendor_service, member)
      rate = vehicle.vendor_service.rates_dataset[params[:rate_id]]
      merror!(403, "Rate does not exist", code: "rate_not_found") if rate.nil?
      begin
        trip = Suma::Mobility::Trip.start_trip_from_vehicle(member:, vehicle:, rate:)
      rescue Suma::Mobility::Trip::OngoingTrip
        merror!(409, "Already in a trip", code: "ongoing_trip")
      end
      add_current_member_header
      status 200
      present trip, with: MobilityTripEntity
    end

    params do
      requires :lat, type: BigDecimal
      requires :lng, type: BigDecimal
    end
    post :end_trip do
      member = current_member
      trip = Suma::Mobility::Trip.ongoing.where(member:).first
      merror!(409, "No ongoing trip", code: "no_active_trip") if trip.nil?
      trip.end_trip(lat: params[:lat], lng: params[:lng])
      add_current_member_header
      status 200
      present trip, with: MobilityTripEntity
    end

    params do
      use :pagination
    end
    get :trips do
      member = current_member
      ds = member.mobility_trips_dataset.ended
      ds = ds.order(Sequel.desc(:began_at), Sequel.desc(:id))
      ds = paginate(ds, params)
      collection = Suma::Service::Collection.from_dataset(ds)
      weeks = []
      if collection.items.any?
        current_week_key = ""
        collection.items.each_with_index do |item, idx|
          began_at = item.began_at.in_time_zone(member.timezone)
          week_key = began_at.beginning_of_week.to_date.to_s
          if week_key == current_week_key
            weeks.last[:end_index] = idx
          else
            current_week_key = week_key
            weeks << {
              begin_at: began_at.beginning_of_week.to_date,
              end_at: began_at.end_of_week.to_date,
              begin_index: idx,
              end_index: idx,
            }
          end
        end
        weeks.last[:end_index] = collection.items.count - 1
      end
      present collection, with: MobilityTripCollectionEntity, ongoing: member.ongoing_trip, weeks:
    end
  end

  class MobilityMapVehicleEntity < BaseEntity
    expose :c
    expose :p
    expose :d, expose_nil: false
    expose :o, expose_nil: false
  end

  class MobilityMapVendorServiceEntity < VendorServiceEntity
    expose :charge_after_fulfillment, as: :zero_balance_ok
  end

  class MobilityMapEntity < BaseEntity
    include Suma::API::Entities
    expose :precision do |_|
      Suma::Mobility::COORD2INT_FACTOR
    end
    expose :refresh do |_|
      30_000
    end
    expose :providers, with: MobilityMapVendorServiceEntity
    expose :escooter, with: MobilityMapVehicleEntity, expose_nil: false
    expose :ebike, with: MobilityMapVehicleEntity, expose_nil: false
  end

  class MobilityMapRestrictionEntity < BaseEntity
    expose :restriction
    expose :multipolygon_numeric, as: :multipolygon
    expose :bounds_numeric, as: :bounds
  end

  class MobilityMapFeaturesEntity < BaseEntity
    expose :restrictions, with: MobilityMapRestrictionEntity
  end

  class MobilityVehicleEntity < BaseEntity
    include Suma::API::Entities
    expose :precision do |_|
      Suma::Mobility::COORD2INT_FACTOR
    end
    expose :vendor_service, with: VendorServiceEntity
    expose :vehicle_id
    expose :to_api_location, as: :loc
    expose :rate, with: VendorServiceRateEntity, &self.delegate_to(:vendor_service, :one_rate)
    expose :deeplink do |vehicle, options|
      vehicle.deep_link_for_user_agent(options.fetch(:request).user_agent)
    end
    expose :goto_private_account do |vehicle, options|
      member = options.fetch(:member)
      now = options.fetch(:current_time)
      vehicle.vendor_service.mobility_adapter.anon_proxy_vendor_account_requires_attention?(member, now:)
    end
  end

  class MobilityTripCollectionEntity < Suma::Service::Collection::BaseEntity
    include Suma::API::Entities
    expose :items, with: MobilityTripEntity
    expose :ongoing, with: MobilityTripEntity do |_, opts|
      opts.fetch(:ongoing)
    end
    expose :weeks do |_, opts|
      opts.fetch(:weeks)
    end
  end
end
