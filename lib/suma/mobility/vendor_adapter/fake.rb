# frozen_string_literal: true

class Suma::Mobility::VendorAdapter::Fake
  include Suma::Mobility::VendorAdapter

  class << self
    attr_accessor :uses_deep_linking,
                  :send_receipts,
                  :find_anon_proxy_vendor_account_results,
                  :end_trip_callback

    def reset
      self.uses_deep_linking = nil
      self.send_receipts = nil
      self.find_anon_proxy_vendor_account_results = []
      self.end_trip_callback = nil
    end
  end

  def uses_deep_linking? = self.class.uses_deep_linking
  def send_receipts? = self.class.send_receipts
  def find_anon_proxy_vendor_account(*) = self.class.find_anon_proxy_vendor_account_results.shift
end
