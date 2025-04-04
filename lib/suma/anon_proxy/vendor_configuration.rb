# frozen_string_literal: true

require "suma/admin_linked"
require "suma/anon_proxy"
require "suma/postgres/model"
require "suma/has_activity_audit"
require "suma/program/has"
require "suma/translated_text"

class Suma::AnonProxy::VendorConfiguration < Suma::Postgres::Model(:anon_proxy_vendor_configurations)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch
  include Suma::HasActivityAudit

  plugin :association_pks
  plugin :hybrid_search
  plugin :timestamps
  plugin :translated_text, :instructions, Suma::TranslatedText
  plugin :translated_text, :linked_success_instructions, Suma::TranslatedText

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

  def hybrid_search_fields
    return [
      :vendor,
      ["Programs", self.programs.map(&:name)],
    ]
  end
end

# Table: anon_proxy_vendor_configurations
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                             | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                     | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                     | timestamp with time zone |
#  vendor_id                      | integer                  | NOT NULL
#  message_handler_key            | text                     | NOT NULL
#  app_install_link               | text                     | NOT NULL
#  enabled                        | boolean                  | NOT NULL
#  instructions_id                | integer                  | NOT NULL
#  auth_to_vendor_key             | text                     | NOT NULL
#  linked_success_instructions_id | integer                  | NOT NULL
#  search_content                 | text                     |
#  search_embedding               | vector(384)              |
#  search_hash                    | text                     |
# Indexes:
#  anon_proxy_vendor_configurations_pkey                          | PRIMARY KEY btree (id)
#  anon_proxy_vendor_configurations_vendor_id_key                 | UNIQUE btree (vendor_id)
#  anon_proxy_vendor_configurations_search_content_tsvector_index | gin (to_tsvector('english'::regconfig, search_content))
# Foreign key constraints:
#  anon_proxy_vendor_configurati_linked_success_instructions__fkey | (linked_success_instructions_id) REFERENCES translated_texts(id)
#  anon_proxy_vendor_configurations_instructions_id_fkey           | (instructions_id) REFERENCES translated_texts(id)
#  anon_proxy_vendor_configurations_vendor_id_fkey                 | (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
# Referenced By:
#  anon_proxy_vendor_accounts                               | anon_proxy_vendor_accounts_configuration_id_fkey                | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id) ON DELETE CASCADE
#  eligibility_anon_proxy_vendor_configuration_associations | eligibility_anon_proxy_vendor_configurati_configuration_id_fkey | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id)
#  programs_anon_proxy_vendor_configurations                | programs_anon_proxy_vendor_configurations_configuration_id_fkey | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id)
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
