# frozen_string_literal: true

require "suma/admin_linked"
require "suma/anon_proxy"
require "suma/postgres"

class Suma::AnonProxy::VendorAccount < Suma::Postgres::Model(:anon_proxy_vendor_accounts)
  include Suma::Postgres::HybridSearch
  include Suma::AdminLinked
  RECENT_ACCESS_CODE_CUTOFF = 10.minutes

  plugin :timestamps

  plugin :hybrid_search

  # @!attribute member
  # @return [Suma::Member]

  # @!attribute configuration
  # @return [Suma::AnonProxy::VendorConfiguration]

  # @!attribute contact
  # @return [Suma::AnonProxy::MemberContact]

  many_to_one :member, class: "Suma::Member"
  many_to_one :configuration, class: "Suma::AnonProxy::VendorConfiguration"
  many_to_one :contact, class: "Suma::AnonProxy::MemberContact"
  one_to_many :messages, class: "Suma::AnonProxy::VendorAccountMessage", order: order_desc
  one_to_many :registrations, class: "Suma::AnonProxy::VendorAccountRegistration", key: :account_id

  class << self
    # Return existing or newly created vendor accounts for the member,
    # using all configured services. Exclude vendor accounts for disabled services.
    # @param member [Suma::Member]
    # @return [Array<Suma::AnonProxy::VendorAccount>]
    def for(member, as_of:)
      return [] unless member.onboarding_verified?

      configs = Suma::AnonProxy::VendorConfiguration.enabled.fetch_eligible_to(member, as_of:)
      valid_configs = configs.index_by(&:id)
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

  # @return [Suma::AnonProxy::AuthToVendor]
  def auth_to_vendor
    return Suma::AnonProxy::AuthToVendor.create!(self.configuration.auth_to_vendor_key, vendor_account: self)
  end

  def needs_linking?(now:) = self.auth_to_vendor.needs_linking?(now:)

  # Return whether the given member requires a payment instrument
  # to use this vendor configuration.
  #
  # We can guess whether a configuration/vendor requires an
  # by looking at current conditions, rather than an explicit flag:
  #
  # - For all programs connected to this configuration,
  # - see if any are in the set of
  #   - programs with pricings with
  #     - nonzero rates
  #     - vendor services from the same vendor as this configuration.
  #
  # If we have any results from this, we probably need pricing,
  # and can ask the user to set up payment before provisioning/linking a vendor account.
  def require_payment_instrument?(as_of:)
    programs = self.configuration.programs_eligible_to(self.member, as_of:)
    nonzero_same_vendor_programs = Suma::Program.where(id: programs.map(&:id)).
      where(
        pricings: Suma::Program::Pricing.where(
          vendor_service_rate: Suma::Vendor::ServiceRate.dataset.nonzero,
          vendor_service: Suma::Vendor::Service.where(vendor: self.configuration.vendor),
        ),
      )
    return !nonzero_same_vendor_programs.empty?
  end

  # Ensure an anonymous email or phone number is provisioned.
  # Note that this takes a lock on the vendor account to avoid potential duplicate provisioning.
  # @param type [:phone, :email]
  def ensure_anonymous_contact(type)
    return self.contact if self.contact
    self.resource_lock! do
      return contact if self.contact
      contact = Suma::AnonProxy::MemberContact.provision_anonymous_contact(self.member, type)
      self.update(contact:)
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

  # To avoid UI logic, we calculate the state the UI should be in,
  # so the frontend can render to that state.
  # Version this so that future UI overhauls can be temporarily compatible with multiple versions.
  # @return [UIStateV1]
  def ui_state_v1(now:)
    needs_linking = self.auth_to_vendor.needs_linking?(now:)
    requires_payment_method = self.require_payment_instrument?(as_of: now)
    has_payment_method = !self.member.default_payment_instrument.nil?
    index_card_mode = if needs_linking
                        :link
                      elsif requires_payment_method && !has_payment_method
                        :payment
                      else
                        :relink
                      end
    return UIStateV1.new(
      index_card_mode:,
      needs_linking:,
      requires_payment_method:,
      has_payment_method:,
      description_text: self.configuration.description_text,
      terms_text: self.configuration.terms_text,
      help_text: self.configuration.help_text,
    )
  end

  # V1 UI state with the following design:
  # - If the account has not been linked, users get a card on the private account list
  #   with a CTA to "Link <vendor> account"
  # - Pressing 'Link <vendor> account" goes to a page where:
  #   - Users are presented a 2 or 3 step process:
  #     - Optional: Add payment method, though:
  #       - This step is missing entirely if +requires_payment_method+ is false.
  #       - This step is shown but skipped if +has_payment_method+ is true.
  #     - Accept terms
  #     - Link account
  #   - On the 'link account' screen, we poll until the code is sent.
  # - If the account has been linked, the user has 'Help' and 'Re-link account' buttons.
  #   - The 'Help' button shows a help modal with dedicated text.
  #   - The 'Re-link account' button follows the same "Link <vendor> account" flow.
  # - If the account has been linked, but there is not a payment method (+has_payment_method+ is false),
  #   present with 'Help' and "Add payment method" buttons. The "Add payment method" button
  #   goes to the same account link process.
  class UIStateV1 < Suma::TypedStruct
    # Which version of the index card to render?
    # See class doc.
    # @return [:link,:relink,:payment]
    attr_reader :index_card_mode
    # True if this account needs to be linked/relinked.
    attr_reader :needs_linking
    # True if this configuration requires a payment method (see +requires_payment_instrument?+).
    # Used to control what the potential flow is.
    attr_reader :requires_payment_method
    # True if the user has a default payment method.
    attr_reader :has_payment_method

    # Localized text for the card description.
    attr_reader :description_text
    # Localized text for the terms agreement step, when the account is linked.
    attr_reader :terms_text
    # Localized text for the help button modal.
    attr_reader :help_text

    requires(all: true)

    def prompt_for_payment_method = self.requires_payment_method && !self.has_payment_method
  end

  def rel_admin_link = "/vendor-account/#{self.id}"

  def hybrid_search_fields
    return [
      :latest_access_code_magic_link,
      :latest_access_code,
      :member,
      ["Vendor", self.configuration.vendor.name],
    ]
  end
end

# Table: anon_proxy_vendor_accounts
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
#  legacy_registered_with_vendor   | text                     |
#  search_content                  | text                     |
#  search_embedding                | vector(384)              |
#  search_hash                     | text                     |
#  pending_closure                 | boolean                  | DEFAULT false
# Indexes:
#  anon_proxy_vendor_accounts_pkey                             | PRIMARY KEY btree (id)
#  anon_proxy_vendor_accounts_configuration_id_contact_id_key  | UNIQUE btree (configuration_id, contact_id)
#  anon_proxy_vendor_accounts_member_id_configuration_id_index | UNIQUE btree (member_id, configuration_id)
#  anon_proxy_vendor_accounts_configuration_id_index           | btree (configuration_id)
#  anon_proxy_vendor_accounts_contact_id_index                 | btree (contact_id)
#  anon_proxy_vendor_accounts_member_id_index                  | btree (member_id)
#  anon_proxy_vendor_accounts_search_content_trigram_index     | gist (search_content)
#  anon_proxy_vendor_accounts_search_content_tsvector_index    | gin (to_tsvector('english'::regconfig, search_content))
# Check constraints:
#  consistent_latest_access_code      | (latest_access_code IS NULL AND latest_access_code_set_at IS NULL OR latest_access_code IS NOT NULL AND latest_access_code_set_at IS NOT NULL)
#  non_empty_vendor_registration      | (legacy_registered_with_vendor IS NULL OR legacy_registered_with_vendor <> ''::text)
#  null_or_present_latest_access_code | (latest_access_code IS NULL OR latest_access_code <> ''::text)
# Foreign key constraints:
#  anon_proxy_vendor_accounts_configuration_id_fkey | (configuration_id) REFERENCES anon_proxy_vendor_configurations(id) ON DELETE CASCADE
#  anon_proxy_vendor_accounts_contact_id_fkey       | (contact_id) REFERENCES anon_proxy_member_contacts(id) ON DELETE SET NULL
#  anon_proxy_vendor_accounts_member_id_fkey        | (member_id) REFERENCES members(id) ON DELETE CASCADE
# Referenced By:
#  anon_proxy_vendor_account_messages      | anon_proxy_vendor_account_messages_vendor_account_id_fkey | (vendor_account_id) REFERENCES anon_proxy_vendor_accounts(id) ON DELETE CASCADE
#  anon_proxy_vendor_account_registrations | anon_proxy_vendor_account_registrations_account_id_fkey   | (account_id) REFERENCES anon_proxy_vendor_accounts(id) ON DELETE CASCADE
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
