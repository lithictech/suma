# frozen_string_literal: true

require "suma/admin_linked"
require "suma/anon_proxy"
require "suma/postgres"

class Suma::AnonProxy::VendorAccount < Suma::Postgres::Model(:anon_proxy_vendor_accounts)
  include Suma::AdminLinked
  RECENT_ACCESS_CODE_CUTOFF = 10.minutes

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
  one_to_many :messages, class: "Suma::AnonProxy::VendorAccountMessage"

  class << self
    # Return existing or newly created vendor accounts for the member,
    # using all configured services. Exclude vendor accounts for disabled services.
    # @param member [Suma::Member]
    # @return [Array<Suma::AnonProxy::VendorAccount>]
    def for(member, as_of:)
      return [] unless member.onboarding_verified?

      ds = Suma::AnonProxy::VendorConfiguration.enabled.eligible_to(member, as_of:)
      valid_configs = ds.
        all.
        index_by(&:id)
      accounts = member.anon_proxy_vendor_accounts_dataset.where(configuration_id: valid_configs.keys).all
      accounts.each { |a| valid_configs.delete(a.configuration_id) }
      unless valid_configs.empty?
        valid_configs.each_value do |configuration|
          # This ::for method must be itself idempotent, as it's meant to be called during GET and similar requests.
          # This is the slow path, only used when there are new configurations, so it's ok to take
          # the additional transactions.
          accounts << Suma::AnonProxy::VendorAccount.find_or_create_or_find(configuration:, member:)
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

  def address = self.email || self.sms
  def address_required? = self.email_required? || self.sms_required?

  # Ensure that the right member contacts exist for what the vendor configuration needs.
  # For example, this may create a phone number in our SMS provider if needed,
  # and the member does not have one; or insert a database object with the member's email.
  def provision_contact
    self.db.transaction do
      self.lock!
      if self.email_required?
        unless (contact = self.member.anon_proxy_contacts.find(&:email?))
          email = Suma::AnonProxy::Relay.active_email_relay.provision(self.member)
          contact = Suma::AnonProxy::MemberContact.create(
            member: self.member,
            email:,
            relay_key: Suma::AnonProxy::Relay.active_email_relay_key,
          )
        end
        self.contact = contact
        self.save_changes
      end
    end
    return self.contact
  end

  def replace_access_code(code, magic_link, at: Time.now)
    self.set(
      latest_access_code: code,
      latest_access_code_magic_link: magic_link,
      latest_access_code_set_at: at,
    )
  end

  def latest_access_code_is_recent?
    return false if self.latest_access_code_set_at.nil? ||
      self.latest_access_code_set_at < RECENT_ACCESS_CODE_CUTOFF.ago
    return true
  end

  # Return the text/plain bodies of outbound message deliveries sent as part of this vendor account.
  # This is useful for when users cannot get messages sent to them, like on non-production environments.
  def recent_message_text_bodies
    # We could select bodies directly, but we'd need to re-sort them.
    # It's not worth it, let's just select VendorAccountMessages and process that ordered list.
    messages = self.messages_dataset.
      where { created_at > RECENT_ACCESS_CODE_CUTOFF.ago }.
      order(Sequel.desc(:created_at)).
      limit(5).
      all
    bodies = []
    messages.each do |m|
      body = m.outbound_delivery.bodies.find { |b| b.mediatype == "text/plain" }
      bodies << body.content if body
    end
    return bodies
  end

  AuthRequest = Struct.new(:url, :http_method, :body, :headers)

  # Return the fields needed to make an auth request.
  # Return nil if the contact is not yet set on the account.
  # @return [AuthRequest,nil]
  def auth_request
    body = self.configuration.auth_body_template % {email: self.contact_email, phone: self.contact_phone}
    return {
      url: self.configuration.auth_url,
      http_method: self.configuration.auth_http_method,
      headers: self.configuration.auth_headers.to_h,
      body:,
    }
  end

  def rel_admin_link = "/vendor-account/#{self.id}"
end

# Table: anon_proxy_vendor_accounts
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                              | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                      | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                      | timestamp with time zone |
#  configuration_id                | integer                  | NOT NULL
#  member_id                       | integer                  | NOT NULL
#  contact_id                      | integer                  |
#  latest_access_code              | text                     |
#  latest_access_code_set_at       | timestamp with time zone |
#  latest_access_code_requested_at | timestamp with time zone |
#  latest_access_code_magic_link   | text                     |
# Indexes:
#  anon_proxy_vendor_accounts_pkey                             | PRIMARY KEY btree (id)
#  anon_proxy_vendor_accounts_configuration_id_contact_id_key  | UNIQUE btree (configuration_id, contact_id)
#  anon_proxy_vendor_accounts_member_id_configuration_id_index | UNIQUE btree (member_id, configuration_id)
#  anon_proxy_vendor_accounts_configuration_id_index           | btree (configuration_id)
#  anon_proxy_vendor_accounts_contact_id_index                 | btree (contact_id)
#  anon_proxy_vendor_accounts_member_id_index                  | btree (member_id)
# Check constraints:
#  consistent_latest_access_code      | (latest_access_code IS NULL AND latest_access_code_set_at IS NULL OR latest_access_code IS NOT NULL AND latest_access_code_set_at IS NOT NULL)
#  null_or_present_latest_access_code | (latest_access_code IS NULL OR latest_access_code <> ''::text)
# Foreign key constraints:
#  anon_proxy_vendor_accounts_configuration_id_fkey | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id) ON DELETE CASCADE
#  anon_proxy_vendor_accounts_contact_id_fkey       | (contact_id) REFERENCES anon_proxy_member_contacts(id) ON DELETE SET NULL
#  anon_proxy_vendor_accounts_member_id_fkey        | (member_id) REFERENCES members(id) ON DELETE CASCADE
# Referenced By:
#  anon_proxy_vendor_account_messages | anon_proxy_vendor_account_messages_vendor_account_id_fkey | (vendor_account_id) REFERENCES anon_proxy_vendor_accounts(id) ON DELETE CASCADE
# ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
