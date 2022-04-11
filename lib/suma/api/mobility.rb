# frozen_string_literal: true

require "grape"

require "suma/api"

class Suma::API::Mobility < Suma::API::V1
  include Suma::Service::Types

  resource :mobility do
    desc "Return all mobility vehicles fitting the requested parameters."
    params do
      requires :minloc, type: Array[BigDecimal], coerce_with: DecimalLocation
      requires :maxloc, type: Array[BigDecimal], coerce_with: DecimalLocation
      optional :types, type: Array[String], coerce_with: CommaSepArray, values: ["ebike", "escooter"]
    end
    get :map do
      current_customer
      min_lat, min_lng = params[:minloc]
      max_lat, max_lng = params[:maxloc]
      ds = Suma::Mobility::Vehicle.search(min_lat:, min_lng:, max_lat:, max_lng:)
      ds = ds.where(vehicle_type: params[:types]) if params.key?(:types)
      ds = ds.where(vendor_service: Suma::Vendor::Service.dataset.mobility)
      ds = ds.order(:id)
      # TODO: Limit to only allowed vendor services for this user.
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
      map_obj[:providers] = vnd_services
      present map_obj, with: Suma::API::MobilityMapEntity
    end

    params do
      requires :loc, type: Array[Integer], coerce_with: IntegerLocation
      requires :provider_id, type: Integer
      requires :type, type: String, values: ["ebike", "escooter"]
      optional :disambiguator, type: String
    end
    get :vehicle do
      current_customer
      matches = Suma::Mobility::Vehicle.where(
        lat: Suma::Mobility.int2coord(params[:loc][0]),
        lng: Suma::Mobility.int2coord(params[:loc][1]),
        vendor_service: Suma::Vendor::Service[params[:provider_id]],
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
      present vehicle, with: Suma::API::MobilityVehicleEntity
    end
  end
end
