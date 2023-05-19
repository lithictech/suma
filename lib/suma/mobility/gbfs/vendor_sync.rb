# frozen_string_literal: true

class Suma::Mobility::Gbfs::BaseSync
  attr_reader :client, :vendor

  def initialize(api_host:, auth_token:, vendor:)
    @client = Suma::Mobility::Gbfs::HttpClient.new(api_host:, auth_token:)
    @vendor = vendor
    @mobility_services = vendor.services_dataset.mobility.all
  end

  def before_sync; end
  def model = raise NotImplementedError
  def build_rows(_vendor_service) = raise NotImplementedError

  def sync_all
    self.before_sync
    rows = []
    @mobility_services.each do |vs|
      rows << self.build_rows(vs)
    end
    self.model.db.transaction do
      Suma::Mobility::RestrictedArea.where(vendor_service: @mobility_services).delete
      Suma::Mobility::RestrictedArea.dataset.multi_insert(rows)
    end
    return rows.length
  end
end
