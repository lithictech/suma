# frozen_string_literal: true

class Suma::Mobility::Gbfs::VendorSync
  attr_reader :client, :vendor, :component

  # @param client [Suma::Mobility::Gbfs::BaseClient]
  def initialize(client:, vendor:, component:)
    @client = client
    @vendor = vendor
    @mobility_services = vendor.services_dataset.mobility.all
    @component = component
  end

  def sync_all
    @component.before_sync(@client)
    rows = []
    @mobility_services.each do |vs|
      @component.yield_rows(vs) { |r| rows << r }
    end
    @component.model.db.transaction do
      @component.model.where(vendor_service: @mobility_services).delete
      @component.model.dataset.insert_conflict.multi_insert(rows)
    end
    return rows.length
  end
end
