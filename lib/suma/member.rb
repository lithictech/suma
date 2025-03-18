# frozen_string_literal: true

require "appydays/configurable"
require "bcrypt"
require "openssl"

require "suma/admin_linked"
require "suma/payment/has_account"
require "suma/postgres/model"
require "suma/secureid"

class Suma::Member < Suma::Postgres::Model(:members)
  extend Suma::MethodUtilities
  include Appydays::Configurable
  include Suma::Payment::HasAccount
  include Suma::AdminLinked

  class InvalidPassword < RuntimeError; end

  class ReadOnlyMode < RuntimeError
    attr_reader :reason

    def initialize(reason)
      @reason = reason
      super("Member is in read-only mode: #{reason}")
    end
  end

  configurable(:member) do
    setting :onboard_allowlist, [], convert: lambda(&:split)
    setting :skip_verification_allowlist, [], convert: lambda(&:split)
    setting :superadmin_allowlist, [], convert: lambda(&:split)
  end

  # The bcrypt hash cost. Changing this would invalidate all passwords!
  # It's only here so we can change it for testing.
  singleton_attr_accessor :password_hash_cost
  @password_hash_cost = 10

  MIN_PASSWORD_LENGTH = 8

  # A bcrypt digest that's valid, but not a real digest. Used as a placeholder for
  # accounts with no passwords, which makes them impossible to authenticate. Or at
  # least much less likely than with a random string.
  PLACEHOLDER_PASSWORD_DIGEST = "$2a$11$....................................................."

  # Regex that matches the prefix of a deleted user's email
  DELETED_EMAIL_PATTERN = /^(?<prefix>\d+(?:\.\d+)?)\+(?<rest>.*)$/

  LATEST_TERMS_PUBLISH_DATE = Date.new(2022, 10, 1)

  plugin :timestamps
  plugin :soft_deletes
  plugin :association_pks
  plugin :hybrid_searchable

  one_to_many :activities, class: "Suma::Member::Activity", order: Sequel.desc([:created_at, :id])
  many_through_many :bank_accounts,
                    [
                      [:legal_entities, :id, :id],
                      [:payment_bank_accounts, :legal_entity_id, :id],
                    ],
                    class: "Suma::Payment::BankAccount",
                    left_primary_key: :legal_entity_id,
                    order: [:created_at, :id],
                    read_only: true
  many_through_many :cards,
                    [
                      [:legal_entities, :id, :id],
                      [:payment_cards, :legal_entity_id, :id],
                    ],
                    class: "Suma::Payment::Card",
                    left_primary_key: :legal_entity_id,
                    order: [:created_at, :id],
                    read_only: true
  one_to_many :charges, class: "Suma::Charge", order: Sequel.desc([:id])
  many_to_one :legal_entity, class: "Suma::LegalEntity"
  one_to_many :message_deliveries, key: :recipient_id, class: "Suma::Message::Delivery"
  one_to_one :preferences, class: "Suma::Message::Preferences"
  one_to_one :ongoing_trip, class: "Suma::Mobility::Trip", conditions: {ended_at: nil}
  many_through_many :orders,
                    [
                      [:commerce_carts, :member_id, :id],
                      [:commerce_checkouts, :cart_id, :id],
                    ],
                    class: "Suma::Commerce::Order",
                    left_primary_key: :id,
                    right_primary_key: :checkout_id,
                    order: Sequel.desc(:created_at),
                    read_only: true
  one_to_one :payment_account, class: "Suma::Payment::Account"
  one_to_one :referral, class: "Suma::Member::Referral"
  one_to_many :reset_codes,
              class: "Suma::Member::ResetCode",
              order: Sequel.desc([:created_at]),
              # Use ResetCode.replace_active instead, add_reset_code is unsafe since it can keep multiple active.
              adder: nil
  many_to_many :roles, class: "Suma::Role", join_table: :roles_members
  one_to_many :sessions, class: "Suma::Member::Session", order: Sequel.desc([:created_at, :id])
  one_to_many :commerce_carts, class: "Suma::Commerce::Cart"
  one_to_many :anon_proxy_contacts, class: "Suma::AnonProxy::MemberContact"
  one_to_many :anon_proxy_vendor_accounts, class: "Suma::AnonProxy::VendorAccount"
  one_to_many :organization_memberships, class: "Suma::Organization::Membership"

  one_to_many :direct_program_enrollments, class: "Suma::Program::Enrollment"
  many_through_many :program_enrollments_via_organizations,
                    [
                      [:organization_memberships, :member_id, :verified_organization_id],
                    ],
                    class: "Suma::Program::Enrollment",
                    left_primary_key: :id,
                    right_primary_key: :organization_id,
                    read_only: true

  many_through_many :program_enrollments_via_roles,
                    [
                      [:roles_members, :member_id, :role_id],
                    ],
                    class: "Suma::Program::Enrollment",
                    left_primary_key: :id,
                    right_primary_key: :role_id,
                    read_only: true

  one_to_many :combined_program_enrollments,
              class: "Suma::Program::Enrollment",
              read_only: true,
              key: :id,
              dataset: lambda {
                # Prefer direct enrollments over indirect ones.
                # The org enrollments being second in the UNION means
                # direct enrollments will be chosen with the DISTINCT.
                self.direct_program_enrollments_dataset.union(
                  self.program_enrollments_via_organizations_dataset,
                  alias: :program_enrollments,
                ).union(
                  self.program_enrollments_via_roles_dataset,
                  alias: :program_enrollments,
                ).order(:program_id, :member_id, :organization_id).distinct(:program_id)
              },
              eager_loader: (proc do |eo|
                eo[:rows].each { |p| p.associations[:combined_program_enrollments] = [] }
                ds = Suma::Program::Enrollment.dataset.
                  for_members(self.where(id: eo[:id_map].keys)).
                  # Get unique enrollments for a program. Prefer direct/member enrollments,
                  # so sort the rows by member_id so NULL member_id rows (indirect/org enrollments)
                  # sort last and are eliminated by the DISTINCT.
                  order(:program_id, :member_id, :organization_id).
                  distinct(:program_id)
                ds.all do |en|
                  m = eo[:id_map][en.member_id || en.values.fetch(:annotated_member_id)].first
                  m.associations[:combined_program_enrollments] << en
                end
              end)

  plugin :association_array_replacer, :roles

  dataset_module do
    def with_email(*emails)
      emails = emails.map { |e| e.downcase.strip }
      return self.where(email: emails)
    end

    def with_normalized_phone(*phones)
      return self.where(phone: phones)
    end
  end

  def self.with_normalized_phone(p)
    return self.dataset.with_normalized_phone(p).first
  end

  def self.with_us_phone(p)
    return self.with_normalized_phone(Suma::PhoneNumber::US.normalize(p))
  end

  def self.with_email(e)
    return self.dataset.with_email(e).first
  end

  def self.matches_allowlist?(member, allowlist)
    return allowlist.any? do |pattern|
      File.fnmatch(pattern, member.phone || "") || File.fnmatch(pattern, member.email || "")
    end
  end

  def initialize(*)
    super
    self[:opaque_id] ||= Suma::Secureid.new_opaque_id("c")
  end

  def ensure_role(role_or_name)
    role = role_or_name.is_a?(Suma::Role) ? role_or_name : Suma::Role[name: role_or_name]
    raise "No role for #{role_or_name}" unless role.present?
    self.add_role(role) unless self.roles_dataset[role.id]
  end

  # Return the +Suma::Member::RoleAccess+ for the member.
  # If a block is given, evaluate it in the context of the role access.
  #
  # @example
  #     can_read = member.role_access { read?(admin_system) }
  #     can_write = member.role_access.write?(:admin_system)
  #
  # @return [Suma::Member::RoleAccess]
  def role_access(&)
    ra = Suma::Member::RoleAccess.new(self)
    return ra.instance_eval(&) if block_given?
    return ra
  end

  def greeting
    return self.name.blank? ? "there" : self.name
  end

  def rel_admin_link = "/member/#{self.id}"

  def onboarded?
    return self.name.present? && self.legal_entity.address_id.present?
  end

  def onboarding_verified?
    return self.onboarding_verified_at ? true : false
  end

  def onboarding_verified=(v)
    self.onboarding_verified_at = v ? Time.now : nil
  end

  def read_only_reason
    return "read_only_unverified" if self.onboarding_verified_at.nil?
    return "read_only_technical_error" if self.payment_account.nil?
    return nil
  end

  def read_only_mode?
    return !!self.read_only_reason
  end

  def read_only_mode!
    reason = self.read_only_reason
    return if reason.nil?
    raise ReadOnlyMode, reason
  end

  def requires_terms_agreement?
    return true if self.terms_agreed.nil?
    return self.terms_agreed < LATEST_TERMS_PUBLISH_DATE
  end

  def usable_payment_instruments
    ord = [Sequel.desc(:created_at), :id]
    result = []
    result.concat(self.legal_entity.bank_accounts_dataset.usable.order(*ord).all) if
      Suma::Payment.method_supported?("bank_account")
    result.concat(self.legal_entity.cards_dataset.usable.order(*ord).all) if
      Suma::Payment.method_supported?("card")
    return result
  end

  def default_payment_instrument
    # In the future we can let them set a default, for now we don't expect many folks to have multiple.
    return self.usable_payment_instruments.first
  end

  def search_label
    lbl = "(#{self.id}) #{self.name}"
    return lbl
  end

  # @return [Suma::Member::StripeAttributes]
  def stripe
    return @stripe ||= Suma::Member::StripeAttributes.new(self)
  end

  # @return [Suma::Member::FrontappAttributes]
  def frontapp
    return @frontapp ||= Suma::Member::FrontappAttributes.new(self)
  end

  def preferences!
    return self.preferences ||= Suma::Message::Preferences.find_or_create_or_find(member: self)
  end
  alias message_preferences preferences
  alias message_preferences! preferences!

  #
  # :section: Organizations
  #

  def ensure_membership_in_organization(org_name)
    org_name = org_name.strip
    got = self.organization_memberships.find do |om|
      om.unverified_organization_name == org_name || om.verified_organization&.name == org_name
    end
    return got if got
    return self.add_organization_membership(unverified_organization_name: org_name)
  end

  #
  # :section: Masking
  #

  def masked_name = _mask(self.name, 2, 2)
  def masked_email = _mask(self.email, 3, 6)
  def masked_phone = _mask((self.phone || "")[1..], 1, 2)

  private def _mask(s, prefix, suffix)
    # If the actual value is too short, always entirely hide it
    minimum_maskable_len = (prefix + suffix) * 1.5
    return "***" if s.blank? || s.length < minimum_maskable_len
    pre = s[...prefix]
    suf = s[-suffix..]
    return "#{pre}***#{suf}"
  end

  #
  # :section: Password
  #

  ### Fetch the user's password as an BCrypt::Password object.
  def encrypted_password
    digest = self.password_digest or return nil
    return BCrypt::Password.new(digest)
  end

  ### Set the password to the given +unencrypted+ String.
  def password=(unencrypted)
    if unencrypted
      self.check_password_complexity(unencrypted)
      self.password_digest = BCrypt::Password.create(unencrypted, cost: self.class.password_hash_cost)
    else
      self.password_digest = BCrypt::Password.new(PLACEHOLDER_PASSWORD_DIGEST)
    end
  end

  ### Attempt to authenticate the user with the specified +unencrypted+ password. Returns
  ### +true+ if the password matched.
  def authenticate(unencrypted)
    return false unless unencrypted
    return false if self.soft_deleted?
    return self.encrypted_password == unencrypted
  end

  ### Raise if +unencrypted+ password does not meet complexity requirements.
  protected def check_password_complexity(unencrypted)
    raise Suma::Member::InvalidPassword, "password must be at least %d characters." % [MIN_PASSWORD_LENGTH] if
      unencrypted.length < MIN_PASSWORD_LENGTH
  end

  def display_email
    return self.email unless self.soft_deleted?
    return self.email.split("+", 2)[1]
  end

  #
  # :section: Phone
  #

  def us_phone
    return Phony.format(self.phone, format: :national)
  end

  def us_phone=(s)
    self.phone = Suma::PhoneNumber::US.normalize(s)
  end

  def phone_last4
    return self.phone[-4..]
  end

  #
  # :section: Sequel Hooks
  #

  def before_create
    self.legal_entity ||= Suma::LegalEntity.create(name: self.name)
    super
  end

  ### Soft-delete hook -- prep the user for deletion.
  def before_soft_delete
    self.email = "#{Time.now.to_f}+#{self[:email]}"
    self.password = "aA1!#{SecureRandom.hex(8)}"
    self.note = (self.note + "\nOriginal phone: #{self.phone}").strip
    # To make sure we clear out the phone, use +37-(13 chars).
    # But we do need to make sure no one already has this phone number.
    loop do
      new_phone = Suma::PhoneNumber.faked_unreachable_phone
      next unless Suma::Member.where(phone: new_phone).empty?
      self.phone = new_phone
      break
    end
    super
  end

  def after_save
    super
    orig_name = self.previous_changes&.fetch(:name, [])&.first || self.name
    change_name = self.legal_entity.name.blank? || self.legal_entity.name == orig_name
    self.legal_entity.update(name: self.name) if change_name
  end

  def hybrid_search_text
    begin
      phone = self.phone.present? && Suma::PhoneNumber::US.format(self.phone)
    rescue ArgumentError
      phone = nil
    end
    lines = [
      "I am a Member.",
      "My name is #{self.name}.",
      !phone && "I do not have a phone number.",
      phone && "My phone number is #{phone}.",
      self.email.blank? && "I do not have an email address.",
      self.email.present? && "My email address is #{self.email}.",
      "I was created on #{self.created_at.httpdate}.",
      !self.onboarding_verified? && "My identity has not been verified.",
      self.soft_deleted? && "I have been deleted.",
      self.roles.include?(Suma::Role.cache.admin) && "I am an administrator.",
      "I am a member of #{self.organization_memberships.count} organizations.",
    ]
    self.organization_memberships.each do |m|
      (n = m.verified_organization&.name) or next
      lines << "I am a member of the organization named #{n}."
    end
    return lines.select(&:present?).join("\n")
  end

  ### Soft-delete hook -- expire unused, unexpired reset codes and
  ### trigger an event on removal.

  #
  # :section: Sequel Validation
  #

  def validate
    super
    self.validates_presence(:phone)
    self.validates_unique(
      :phone,
      message: "is already taken. If you're trying to duplicate a member, " \
               "make sure that you soft-delete their account first.",
    )
    unless self.soft_deleted?
      self.validates_format(Suma::PhoneNumber::US::REGEXP, :phone, message: "is not an 11 digit US phone number")
    end
    return if self[:email].nil?
    self.validates_unique(:email)
    self.validates_operator(:==, self.email.downcase.strip, :email)
  end
end

require "suma/member/exporter"
require "suma/member/frontapp_attributes"
require "suma/member/role_access"
require "suma/member/stripe_attributes"

# Table: members
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                     | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at             | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at             | timestamp with time zone |
#  soft_deleted_at        | timestamp with time zone |
#  password_digest        | text                     | NOT NULL
#  opaque_id              | text                     | NOT NULL
#  email                  | citext                   |
#  phone                  | text                     | NOT NULL
#  name                   | text                     | NOT NULL DEFAULT ''::text
#  note                   | text                     | NOT NULL DEFAULT ''::text
#  timezone               | text                     | NOT NULL DEFAULT 'America/Los_Angeles'::text
#  onboarding_verified_at | timestamp with time zone |
#  legal_entity_id        | integer                  | NOT NULL
#  terms_agreed           | date                     |
#  stripe_customer_json   | jsonb                    |
#  frontapp_contact_id    | text                     | NOT NULL DEFAULT ''::text
#  lime_user_id           | text                     | NOT NULL DEFAULT ''::text
# Indexes:
#  members_pkey      | PRIMARY KEY btree (id)
#  members_email_key | UNIQUE btree (email)
#  members_phone_key | UNIQUE btree (phone)
# Check constraints:
#  email_present           | (email IS NULL OR length(email::text) > 0)
#  lowercase_nospace_email | (email::text = btrim(lower(email::text)))
#  numeric_phone           | (phone ~ '^[0-9]{11,15}$'::text)
# Foreign key constraints:
#  members_legal_entity_id_fkey | (legal_entity_id) REFERENCES legal_entities(id) ON DELETE RESTRICT
# Referenced By:
#  anon_proxy_member_contacts             | anon_proxy_member_contacts_member_id_fkey               | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  anon_proxy_vendor_accounts             | anon_proxy_vendor_accounts_member_id_fkey               | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  charges                                | charges_member_id_fkey                                  | (member_id) REFERENCES members(id)
#  commerce_carts                         | commerce_carts_member_id_fkey                           | (member_id) REFERENCES members(id)
#  commerce_order_audit_logs              | commerce_order_audit_logs_actor_id_fkey                 | (actor_id) REFERENCES members(id) ON DELETE SET NULL
#  eligibility_member_associations        | eligibility_member_associations_pending_member_id_fkey  | (pending_member_id) REFERENCES members(id)
#  eligibility_member_associations        | eligibility_member_associations_rejected_member_id_fkey | (rejected_member_id) REFERENCES members(id)
#  eligibility_member_associations        | eligibility_member_associations_verified_member_id_fkey | (verified_member_id) REFERENCES members(id)
#  member_activities                      | member_activities_member_id_fkey                        | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  member_linked_legal_entities           | member_linked_legal_entities_member_id_fkey             | (member_id) REFERENCES members(id)
#  member_referrals                       | member_referral_member_id_fkey                          | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  member_reset_codes                     | member_reset_codes_member_id_fkey                       | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  member_sessions                        | member_sessions_impersonating_id_fkey                   | (impersonating_id) REFERENCES members(id) ON DELETE SET NULL
#  member_sessions                        | member_sessions_member_id_fkey                          | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  member_surveys                         | member_surveys_member_id_fkey                           | (member_id) REFERENCES members(id)
#  message_deliveries                     | message_deliveries_recipient_id_fkey                    | (recipient_id) REFERENCES members(id) ON DELETE SET NULL
#  message_preferences                    | message_preferences_member_id_fkey                      | (member_id) REFERENCES members(id)
#  mobility_trips                         | mobility_trips_member_id_fkey                           | (member_id) REFERENCES members(id)
#  organization_memberships               | organization_memberships_member_id_fkey                 | (member_id) REFERENCES members(id)
#  payment_accounts                       | payment_accounts_member_id_fkey                         | (member_id) REFERENCES members(id)
#  payment_book_transactions              | payment_book_transactions_actor_id_fkey                 | (actor_id) REFERENCES members(id) ON DELETE SET NULL
#  payment_funding_transaction_audit_logs | payment_funding_transaction_audit_logs_actor_id_fkey    | (actor_id) REFERENCES members(id) ON DELETE SET NULL
#  payment_payout_transaction_audit_logs  | payment_payout_transaction_audit_logs_actor_id_fkey     | (actor_id) REFERENCES members(id) ON DELETE SET NULL
#  program_enrollments                    | program_enrollments_approved_by_id_fkey                 | (approved_by_id) REFERENCES members(id) ON DELETE SET NULL
#  program_enrollments                    | program_enrollments_member_id_fkey                      | (member_id) REFERENCES members(id) ON DELETE CASCADE
#  program_enrollments                    | program_enrollments_unenrolled_by_id_fkey               | (unenrolled_by_id) REFERENCES members(id) ON DELETE SET NULL
#  roles_members                          | roles_members_member_id_fkey                            | (member_id) REFERENCES members(id)
#  uploaded_files                         | uploaded_files_created_by_id_fkey                       | (created_by_id) REFERENCES members(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------
