# frozen_string_literal: true

require "suma/anon_proxy"
require "suma/eligibility/has_constraints"
require "suma/postgres"
require "suma/translated_text"

class Suma::AnonProxy::VendorConfiguration < Suma::Postgres::Model(:anon_proxy_vendor_configurations)
  plugin :timestamps
  plugin :translated_text, :instructions, Suma::TranslatedText

  many_to_one :vendor, class: "Suma::Vendor"
  one_to_many :accounts, class: "Suma::AnonProxy::VendorAccount", key: :configuration_id

  many_to_many :eligibility_constraints,
               class: "Suma::Eligibility::Constraint",
               join_table: :eligibility_anon_proxy_vendor_configuration_associations,
               right_key: :constraint_id,
               left_key: :configuration_id
  include Suma::Eligibility::HasConstraints

  dataset_module do
    def enabled
      return self.where(enabled: true)
    end
  end

  def uses_email? = self.uses_email
  def uses_sms? = self.uses_sms
  def enabled? = self.enabled
end
