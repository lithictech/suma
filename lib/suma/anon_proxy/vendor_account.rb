# frozen_string_literal: true

require "suma/postgres"
require "suma/anon_proxy"

class Suma::AnonProxy::VendorAccount < Suma::Postgres::Model(:anon_proxy_vendor_accounts)
  plugin :timestamps

  # @!attribute member
  # @return [Suma::Member]

  # @!attribute configuration
  # @return [Suma::AnonProxy::VendorConfiguration]

  # @!attribute contact
  # @return [Suma::AnonProxy::MemberContact]

  many_to_one :member, class: "Suma::Member"
  many_to_one :configuration, class: "Suma::AnonProxy::VendorConfiguration"
  many_to_one :contact, class: "Suma::AnonProxy::MemberContact"

  class << self
    # Return existing or newly created vendor accounts for the member,
    # using all configured services. Exclude vendor accounts for disabled services.
    # @return [Array<Suma::AnonProxy::VendorAccount>]
    def for(member)
      valid_configs = Suma::AnonProxy::VendorConfiguration.enabled.all.index_by(&:id)
      accounts = member.anon_proxy_vendor_accounts_dataset.where(configuration_id: valid_configs.keys).all
      accounts.each { |a| valid_configs.delete(a.configuration_id) }
      unless valid_configs.empty?
        self.db.transaction do
          valid_configs.each_value do |configuration|
            accounts << member.add_anon_proxy_vendor_account(configuration:)
          end
        end
      end
      return accounts
    end
  end

  def contact_phone = self.contact&.phone
  def contact_email = self.contact&.email

  def sms = self.configuration.uses_sms? ? self.contact_phone : nil
  def sms_required? = self.configuration.uses_sms? && self.contact_phone.nil?

  def email = self.configuration.uses_email? ? self.contact_email : nil
  def email_required? = self.configuration.uses_email? && self.contact_email.nil?

  # Ensure that the right member contacts exist for what the vendor configuration needs.
  # For example, this may create a phone number in our SMS provider if needed,
  # and the member does not have one; or insert a database object with the member's email.
  def provision_contact
    self.db.transaction do
      self.lock!
      if self.email_required?
        unless (contact = self.member.anon_proxy_contacts.find(&:email?))
          email = Suma::AnonProxy::Email.active_provider.provision(self.member)
          contact = Suma::AnonProxy::MemberContact.create(
            member: self.member,
            email:,
            provider_key: Suma::AnonProxy::Email.active_provider_key,
          )
        end
        self.contact = contact
        self.save_changes
      end
    end
    return self.contact
  end
end
