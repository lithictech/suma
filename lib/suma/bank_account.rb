# frozen_string_literal: true

require "suma/payment/instrument"
require "suma/postgres/model"

class Suma::BankAccount < Suma::Postgres::Model(:bank_accounts)
  include Suma::Payment::Instrument
  plugin :timestamps
  plugin :soft_deletes

  many_to_one :plaid_institution, class: "Suma::PlaidInstitution"
  many_to_one :legal_entity, class: "Suma::LegalEntity"
  one_through_many :customer,
                   [
                     [:legal_entities, :id, :id],
                     [:customers, :legal_entity_id, :id],
                   ],
                   class: "Suma::Customer",
                   left_primary_key: :legal_entity_id

  dataset_module do
    def usable
      return self.not_soft_deleted
    end
  end

  def verified?
    return !!self.verified_at
  end

  def payment_method_type
    return "bank_account"
  end

  def last4
    return self.account_number[-4..]
  end

  def name_with_last4
    return "#{self.name} x-#{self.last4}"
  end

  def to_display
    inst = self.plaid_institution
    return Display.new(
      institution_name: inst&.name || "Unknown",
      institution_logo: inst&.logo_base64 || "",
      institution_color: inst&.primary_color_hex || "#000000",
      name: self.name,
      last4: self.last4,
    )
  end

  def reassociate_plaid_institution
    # routing number is non-nullable so we should never hit this.
    raise Suma::InvalidPrecondition, "routing number cannot be blank" if self.routing_number.blank?
    matches = Suma::PlaidInstitution.where(Sequel.pg_array_op(:routing_numbers).contains([self.routing_number]))
    self.plaid_institution = matches.first
  end

  def before_save
    self.reassociate_plaid_institution if self.id.nil? || self.changed_columns.include?(:routing_number)
    super
  end
end
