# frozen_string_literal: true

require "suma/admin_linked"
require "suma/payment"

class Suma::Payment::Instrument < Suma::Postgres::Model(:payment_instruments)
  module Interface
    include Suma::AdminLinked

    def self.included(m)
      m.many_to_one :legal_entity, class: "Suma::LegalEntity"
      m.one_through_many :member,
                         [
                           [:legal_entities, :id, :id],
                           [:members, :legal_entity_id, :id],
                         ],
                         class: "Suma::Member",
                         left_primary_key: :legal_entity_id
    end

    # 'card', 'bank_account', etc.
    def payment_method_type = raise NotImplementedError
    # Return true if the instance can be used for funding.
    # This should not check whether the instance is soft-deleted,
    # just that other fields are set up to be able to use for funding.
    def usable_for_funding? = raise NotImplementedError
    # See +usable_for_funding?+.
    def usable_for_payout? = raise NotImplementedError
    # When does this expire? False if unexpired, or not supporting expiration.
    def expires_at = raise NotImplementedError
    # Is this account verified, for whatever the instrument's meaning of verified is.
    def verified? = raise NotImplementedError
    # @return [String]
    def institution_name = raise NotImplementedError

    def rel_admin_link = "/#{self.payment_method_type.dasherize}/#{self.id}"

    def expired_as_of?(t) = self.expires_at.nil? ? false : self.expires_at <= t
    def expired? = self.expired_as_of?(Time.now)

    def status
      return :expired if expired?
      return :unverified unless verified?
      return :ok
    end

    def admin_label
      lbl = self.simple_label
      inst_name = self.institution_name
      lbl += " (#{inst_name})" unless self.name&.include?(inst_name || "")
      return lbl
    end

    def simple_label = raise NotImplementedError

    def search_label
      lbl = "#{self.legal_entity.name}: #{self.name}, #{self.institution_name}"
      return lbl
    end
  end

  include Interface

  plugin :hybrid_search, indexable: false
  plugin :soft_deletes

  dataset_module do
    def usable_for_funding = self.where(usable_for_funding: true)
    def usable_for_payout = self.where(usable_for_payout: true)
    def unexpired_as_of(t) = self.where((Sequel[:expires_at] =~ nil) | (Sequel[:expires_at] > Sequel[t]))
    def expired_as_of(t) = self.where { expires_at <= Sequel[t] }
    def for(type, id) = self.where(payment_method_type: type, instrument_id: id)
  end

  def payment_method_type = self[:payment_method_type]
  def usable_for_funding? = self[:usable_for_funding]
  def usable_for_payout? = self[:usable_for_payout]
  def expires_at = self[:expires_at]
  def verified? = self[:verified]
  def institution_name = self[:institution_name]
  def refetch_remote_data = nil
  def reify = Suma::Payment::Instrument.reify([self]).first

  class << self
    def read_only? = true
    def primary_key = :pk

    def type_strings_to_types
      return @type_strings_to_types ||= {
        Suma::Payment::BankAccount.new.payment_method_type => Suma::Payment::BankAccount,
        Suma::Payment::Card.new.payment_method_type => Suma::Payment::Card,
      }
    end

    # Given an array of instrument rows, return an array where each instrument row
    # has been replaced with its concrete type (+Suma::Card+, etc), with the same order.
    def reify(rows)
      ids_by_type = {}
      rows.each do |r|
        ids = (ids_by_type[r.payment_method_type] ||= [])
        ids << r.instrument_id
      end
      instances_by_type = {}
      ids_by_type.each do |t, ids|
        type = self.type_strings_to_types.fetch(t)
        instances_by_type[t] = type.dataset.where(type.primary_key => ids).all.index_by(&type.primary_key)
      end
      result = rows.map { |r| instances_by_type[r.payment_method_type].fetch(r.instrument_id) }
      return result
    end

    def post_create_cleanup(instrument, now:)
      instrument.legal_entity.cards_dataset.expired_as_of(now).each(&:soft_delete)
    end
  end
end

# Table: payment_instruments
# -------------------------------------------------
# Columns:
#  pk                  | text                     |
#  instrument_id       | integer                  |
#  payment_method_type | text                     |
#  name                | text                     |
#  institution_name    | text                     |
#  legal_entity_id     | integer                  |
#  usable_for_funding  | boolean                  |
#  usable_for_payout   | boolean                  |
#  expires_at          | timestamp with time zone |
#  verified            | boolean                  |
#  soft_deleted_at     | timestamp with time zone |
#  search_content      | text                     |
#  search_embedding    | vector(384)              |
#  search_hash         | text                     |
# -------------------------------------------------
