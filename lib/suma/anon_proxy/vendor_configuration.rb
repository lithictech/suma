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

  def auth_request
    return {
      url: self.auth_url,
      content_type: self.auth_content_type,
      params: self.auth_params,
      headers: self.auth_headers,
    }
  end
end

# Table: anon_proxy_vendor_configurations
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                  | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at          | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at          | timestamp with time zone |
#  vendor_id           | integer                  | NOT NULL
#  uses_email          | boolean                  | NOT NULL
#  uses_sms            | boolean                  | NOT NULL
#  message_handler_key | text                     | NOT NULL
#  app_launch_link     | text                     | NOT NULL
#  enabled             | boolean                  | NOT NULL
#  instructions_id     | integer                  | NOT NULL
# Indexes:
#  anon_proxy_vendor_configurations_pkey          | PRIMARY KEY btree (id)
#  anon_proxy_vendor_configurations_vendor_id_key | UNIQUE btree (vendor_id)
# Check constraints:
#  unambiguous_contact_type | (uses_email IS NOT FALSE AND uses_sms IS FALSE OR uses_email IS FALSE AND uses_sms IS NOT FALSE)
# Foreign key constraints:
#  anon_proxy_vendor_configurations_instructions_id_fkey | (instructions_id) REFERENCES translated_texts(id)
#  anon_proxy_vendor_configurations_vendor_id_fkey       | (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
# Referenced By:
#  anon_proxy_vendor_accounts                               | anon_proxy_vendor_accounts_configuration_id_fkey                | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id) ON DELETE CASCADE
#  eligibility_anon_proxy_vendor_configuration_associations | eligibility_anon_proxy_vendor_configurati_configuration_id_fkey | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
