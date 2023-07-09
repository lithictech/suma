# frozen_string_literal: true

require "suma/postgres"
require "suma/anon_proxy"
require "suma/translated_text"

class Suma::AnonProxy::VendorConfiguration < Suma::Postgres::Model(:anon_proxy_vendor_configurations)
  plugin :timestamps
  plugin :translated_text, :instructions, Suma::TranslatedText

  many_to_one :vendor, class: "Suma::Vendor"

  dataset_module do
    def enabled
      return self.where(enabled: true)
    end
  end

  def uses_email? = self.uses_email
  def uses_sms? = self.uses_sms
  def enabled? = self.enabled
end
