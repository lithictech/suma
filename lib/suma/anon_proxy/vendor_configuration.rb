# frozen_string_literal: true

require "suma/admin_linked"
require "suma/anon_proxy"
require "suma/postgres"
require "suma/program/has"
require "suma/translated_text"

class Suma::AnonProxy::VendorConfiguration < Suma::Postgres::Model(:anon_proxy_vendor_configurations)
  include Suma::AdminLinked
  plugin :timestamps
  plugin :translated_text, :instructions, Suma::TranslatedText
  plugin :translated_text, :linked_success_instructions, Suma::TranslatedText
  plugin :association_pks

  many_to_one :vendor, class: "Suma::Vendor"
  one_to_many :accounts, class: "Suma::AnonProxy::VendorAccount", key: :configuration_id

  many_to_many :programs,
               class: "Suma::Program",
               join_table: :programs_anon_proxy_vendor_configurations,
               left_key: :configuration_id
  include Suma::Program::Has

  dataset_module do
    def enabled
      return self.where(enabled: true)
    end
  end

  # True if the instance is enabled/should show in the UI.
  def enabled? = self.enabled

  def rel_admin_link = "/vendor-configuration/#{self.id}"
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
#  app_install_link    | text                     | NOT NULL
#  enabled             | boolean                  | NOT NULL
#  instructions_id     | integer                  | NOT NULL
#  auth_http_method    | text                     | NOT NULL DEFAULT 'POST'::text
#  auth_url            | text                     | NOT NULL
#  auth_headers        | jsonb                    | NOT NULL
#  auth_body_template  | text                     | NOT NULL
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
#  programs_anon_proxy_vendor_configurations                | programs_anon_proxy_vendor_configurations_configuration_id_fkey | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
