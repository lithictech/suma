# frozen_string_literal: true

require "suma/admin_linked"
require "suma/external_links"
require "suma/payment/instrument"
require "suma/postgres/model"

class Suma::Payment::BankAccount < Suma::Postgres::Model(:payment_bank_accounts)
  include Suma::Payment::Instrument
  include Suma::AdminLinked
  include Suma::ExternalLinks

  plugin :timestamps
  plugin :soft_deletes
  plugin :column_encryption do |enc|
    enc.column :account_number
  end

  many_to_one :plaid_institution, class: "Suma::PlaidInstitution"
  many_to_one :legal_entity, class: "Suma::LegalEntity"
  one_through_many :member,
                   [
                     [:legal_entities, :id, :id],
                     [:members, :legal_entity_id, :id],
                   ],
                   class: "Suma::Member",
                   left_primary_key: :legal_entity_id

  dataset_module do
    def usable
      return self.not_soft_deleted
    end

    def verified
      return self.exclude(verified_at: nil)
    end
  end

  # Create a stable identity for this account. We encrypt the account number
  # so cannot use it in our unique constraint.
  def self.identity(legal_entity_id, routing_number, account_number)
    return Digest::SHA512.hexdigest("#{legal_entity_id}|#{routing_number}|#{account_number}")
  end

  def verified?
    return !!self.verified_at
  end

  def verified=(v)
    self.verified_at = v.nil? ? nil : Time.now
  end

  def payment_method_type
    return "bank_account"
  end

  def last4
    return self.account_number[-4..]
  end

  def can_use_for_funding?
    return self.verified?
  end

  def name_with_last4
    return "#{self.name} x-#{self.last4}"
  end

  def rel_admin_link = "/bank-account/#{self.id}"

  def institution
    inst = self.plaid_institution
    return Institution.new(
      name: inst&.name || "Unknown",
      logo: inst&.logo_base64 || "",
      color: inst&.primary_color_hex || "#000000",
    )
  end

  def reassociate_plaid_institution
    # routing number is non-nullable so we should never hit this.
    raise Suma::InvalidPrecondition, "routing number cannot be blank" if self.routing_number.blank?
    matches = Suma::PlaidInstitution.where(Sequel.pg_array_op(:routing_numbers).contains([self.routing_number]))
    self.plaid_institution = matches.first
  end

  def before_validation
    self[:identity] = self.class.identity(self.legal_entity_id, self.routing_number, self.account_number)
    super
  end

  def before_save
    self.reassociate_plaid_institution if self.id.nil? || self.changed_columns.include?(:routing_number)
    super
  end
end

# Table: payment_bank_accounts
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                   | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at           | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at           | timestamp with time zone |
#  soft_deleted_at      | timestamp with time zone |
#  verified_at          | timestamp with time zone |
#  routing_number       | text                     | NOT NULL
#  account_number       | text                     | NOT NULL
#  legal_entity_id      | integer                  | NOT NULL
#  plaid_institution_id | integer                  |
#  name                 | text                     | NOT NULL
#  account_type         | text                     | NOT NULL
#  identity             | text                     | NOT NULL
# Indexes:
#  bank_accounts_pkey                         | PRIMARY KEY btree (id)
#  unique_undeleted_bank_account_identity_key | UNIQUE btree (identity) WHERE soft_deleted_at IS NULL
# Foreign key constraints:
#  bank_accounts_legal_entity_id_fkey      | (legal_entity_id) REFERENCES legal_entities(id) ON DELETE RESTRICT
#  bank_accounts_plaid_institution_id_fkey | (plaid_institution_id) REFERENCES plaid_institutions(pk) ON DELETE SET NULL
# Referenced By:
#  commerce_checkouts                                  | commerce_checkouts_bank_account_id_fkey                         | (bank_account_id) REFERENCES payment_bank_accounts(id)
#  payment_funding_transaction_increase_ach_strategies | payment_funding_transaction_in_originating_bank_account_id_fkey | (originating_bank_account_id) REFERENCES payment_bank_accounts(id)
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
