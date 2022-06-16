# frozen_string_literal: true

require "suma/external_links"
require "suma/payment/instrument"
require "suma/postgres/model"

class Suma::BankAccount < Suma::Postgres::Model(:bank_accounts)
  include Suma::Payment::Instrument
  include Suma::ExternalLinks

  plugin :timestamps
  plugin :soft_deletes

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

  def admin_link
    return "#{Suma.admin_url}/bank-accounts/#{self.id}"
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
