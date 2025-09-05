# frozen_string_literal: true

require "suma/payment"

class Suma::Payment::Instrument < Suma::Postgres::Model(:payment_instruments)
  plugin :hybrid_search, indexable: false

  class << self
    def primary_key = :id

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
        ids = (ids_by_type[r.type] ||= [])
        ids << r.id
      end
      instances_by_type = {}
      ids_by_type.each do |t, ids|
        type = self.type_strings_to_types.fetch(t)
        instances_by_type[t] = type.dataset.where(type.primary_key => ids).all.index_by(&type.primary_key)
      end
      result = rows.map { |r| instances_by_type[r.type].fetch(r.id) }
      return result
    end
  end

  module Interface
    def payment_method_type = raise NotImplementedError
    def rel_admin_link = raise NotImplementedError
    def can_use_for_funding? = raise NotImplementedError
    # @return [Institution]
    def institution = raise NotImplementedError

    def admin_label
      lbl = "#{self.name}/#{self.last4}"
      inst_name = self.institution.name
      lbl += " (#{inst_name})" unless self.name&.include?(inst_name || "")
      return lbl
    end

    def simple_label = raise NotImplementedError

    def search_label
      lbl = "#{self.legal_entity.name}: #{self.name} x-#{self.last4}, #{self.institution.name}"
      return lbl
    end
  end
end
