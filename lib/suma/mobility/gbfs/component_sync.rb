# frozen_string_literal: true

class Suma::Mobility::Gbfs::ComponentSync
  # @param client [Suma::Mobility::Gbfs::Client]
  def before_sync(client); end
  def model = raise NotImplementedError
  # @param vendor_service [Suma::Vendor::Service]
  def yield_rows(vendor_service) = raise NotImplementedError
end
