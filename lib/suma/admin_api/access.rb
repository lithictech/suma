# frozen_string_literal: true

class Suma::AdminAPI::Access
  ALL = Suma::Member::RoleAccess::ADMIN_ACCESS
  MEMBERS = Suma::Member::RoleAccess::ADMIN_MEMBERS
  COMMERCE = Suma::Member::RoleAccess::ADMIN_COMMERCE
  PAYMENTS = Suma::Member::RoleAccess::ADMIN_PAYMENTS
  MANAGEMENT = Suma::Member::RoleAccess::ADMIN_MANAGEMENT

  MAPPING = {
    Suma::AnonProxy::VendorAccount => [:vendor_account, COMMERCE, COMMERCE],
    Suma::AnonProxy::VendorConfiguration => [:vendor_configuration, COMMERCE, COMMERCE],
    Suma::Payment::BankAccount => [:bank_account, MEMBERS, MEMBERS],
    Suma::Payment::BookTransaction => [:book_transaction, PAYMENTS, PAYMENTS],
    Suma::Commerce::OfferingProduct => [:offering_product, COMMERCE, COMMERCE],
    Suma::Commerce::Offering => [:offering, COMMERCE, COMMERCE],
    Suma::Commerce::Order => [:order, COMMERCE, COMMERCE],
    Suma::Commerce::Product => [:product, COMMERCE, COMMERCE],
    Suma::Eligibility::Constraint => [:eligibility_constraint, ALL, MANAGEMENT],
    Suma::Payment::FundingTransaction => [:funding_transaction, PAYMENTS, PAYMENTS],
    Suma::Member => [:member, MEMBERS, MEMBERS],
    Suma::Message::Delivery => [:message_delivery, MEMBERS, MANAGEMENT],
    Suma::Organization::Membership => [:organization_membership, MEMBERS, MEMBERS],
    Suma::Organization => [:organization, MEMBERS, MANAGEMENT],
    Suma::Payment::Ledger => [:ledger, PAYMENTS, PAYMENTS],
    Suma::Payment::Trigger => [:payment_trigger, PAYMENTS, MANAGEMENT],
    Suma::Payment::PayoutTransaction => [:payout_transaction, PAYMENTS, PAYMENTS],
    Suma::Role => [:role, ALL, MANAGEMENT],
    Suma::Vendible::Group => [:vendible_group, COMMERCE, COMMERCE],
    Suma::Vendor::Service => [:vendor_service, COMMERCE, COMMERCE],
    Suma::Vendor => [:vendor, COMMERCE, MANAGEMENT],
  }.freeze

  class << self
    def read_key(resource) = can?(resource, 1)
    def write_key(resource) = can?(resource, 2)

    private def can?(resource, idx)
      v = MAPPING[resource] or return false
      key = v[idx]
      return key
    end

    def as_json
      return MAPPING.values.each_with_object({}) do |v, acc|
        acc[v[0]] = [v[1], v[2]]
      end
    end
  end
end