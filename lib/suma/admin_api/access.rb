# frozen_string_literal: true

class Suma::AdminAPI::Access
  ALL = Suma::Member::RoleAccess::ADMIN_ACCESS
  MEMBERS = Suma::Member::RoleAccess::ADMIN_MEMBERS
  COMMERCE = Suma::Member::RoleAccess::ADMIN_COMMERCE
  PAYMENTS = Suma::Member::RoleAccess::ADMIN_PAYMENTS
  SENSITIVE_MESSAGES = Suma::Member::RoleAccess::ADMIN_SENSITIVE_MESSAGES
  MANAGEMENT = Suma::Member::RoleAccess::ADMIN_MANAGEMENT
  MARKETING_SMS = Suma::Member::RoleAccess::MARKETING_SMS
  LOCALIZATION = Suma::Member::RoleAccess::LOCALIZATION

  MAPPING = {
    Suma::AnonProxy::MemberContact => [:anon_member_contact, COMMERCE, MANAGEMENT],
    Suma::AnonProxy::VendorAccount => [:vendor_account, COMMERCE, COMMERCE],
    Suma::AnonProxy::VendorConfiguration => [:vendor_configuration, COMMERCE, COMMERCE],
    Suma::Payment::BankAccount => [:bank_account, MEMBERS, MEMBERS],
    Suma::Payment::BookTransaction => [:book_transaction, PAYMENTS, PAYMENTS],
    Suma::Charge => [:charge, PAYMENTS, PAYMENTS],
    Suma::Commerce::OfferingProduct => [:offering_product, COMMERCE, COMMERCE],
    Suma::Commerce::Offering => [:offering, COMMERCE, COMMERCE],
    Suma::Commerce::Order => [:order, COMMERCE, COMMERCE],
    Suma::Commerce::Product => [:product, COMMERCE, COMMERCE],
    Suma::I18n::StaticString => [:static_string, ALL, LOCALIZATION],
    Suma::Payment::FundingTransaction => [:funding_transaction, PAYMENTS, PAYMENTS],
    Suma::Marketing::List => [:marketing_list, MARKETING_SMS, MARKETING_SMS],
    Suma::Marketing::SmsBroadcast => [:marketing_sms_broadcast, MARKETING_SMS, MARKETING_SMS],
    Suma::Marketing::SmsDispatch => [:marketing_sms_dispatch, MARKETING_SMS, MARKETING_SMS],
    Suma::Member => [:member, MEMBERS, MEMBERS],
    Suma::Message::Delivery => [:message_delivery, MEMBERS, MANAGEMENT],
    Suma::Mobility::Trip => [:mobility_trip, COMMERCE, MANAGEMENT],
    Suma::Organization::Membership => [:organization_membership, MEMBERS, MEMBERS],
    Suma::Organization::Membership::Verification => [:organization_membership_verification, MEMBERS, MEMBERS],
    Suma::Organization => [:organization, MEMBERS, MANAGEMENT],
    Suma::Payment::Ledger => [:ledger, PAYMENTS, PAYMENTS],
    Suma::Payment::Trigger => [:payment_trigger, PAYMENTS, MANAGEMENT],
    Suma::Payment::PayoutTransaction => [:payout_transaction, PAYMENTS, PAYMENTS],
    Suma::Program => [:program, ALL, MANAGEMENT],
    Suma::Program::Enrollment => [:program_enrollment, ALL, MANAGEMENT],
    Suma::Role => [:role, ALL, MANAGEMENT],
    Suma::Vendor::Service => [:vendor_service, COMMERCE, COMMERCE],
    Suma::Vendor => [:vendor, COMMERCE, MANAGEMENT],
  }.freeze

  class << self
    def read_key(resource) = can?(resource, 1)
    def write_key(resource) = can?(resource, 2)

    private def can?(resource, idx)
      v = MAPPING.fetch(resource)
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
