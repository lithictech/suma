# frozen_string_literal: true

require "appydays/configurable"
require "bcrypt"
require "openssl"

require "suma/payment/has_account"
require "suma/postgres/model"
require "suma/secureid"

class Suma::Member < Suma::Postgres::Model(:members)
  extend Suma::MethodUtilities
  include Appydays::Configurable
  include Suma::Payment::HasAccount

  class InvalidPassword < RuntimeError; end
  class ReadOnlyMode < RuntimeError; end

  configurable(:member) do
    setting :skip_verification_allowlist, [], convert: ->(s) { s.split }
    setting :superadmin_allowlist, [], convert: ->(s) { s.split }
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

  plugin :timestamps
  plugin :soft_deletes

  one_to_many :activities, class: "Suma::Member::Activity", order: Sequel.desc([:created_at, :id])
  many_through_many :bank_accounts,
                    [
                      [:legal_entities, :id, :id],
                      [:bank_accounts, :legal_entity_id, :id],
                    ],
                    class: "Suma::BankAccount",
                    left_primary_key: :legal_entity_id,
                    order: [:created_at, :id]
  one_to_many :charges, class: "Suma::Charge", order: Sequel.desc([:id])
  many_to_one :legal_entity, class: "Suma::LegalEntity"
  one_to_many :message_deliveries, key: :recipient_id, class: "Suma::Message::Delivery"
  one_to_one :ongoing_trip, class: "Suma::Mobility::Trip", conditions: {ended_at: nil}
  one_to_one :payment_account, class: "Suma::Payment::Account"
  one_to_many :reset_codes, class: "Suma::Member::ResetCode", order: Sequel.desc([:created_at])
  many_to_many :roles, class: "Suma::Role", join_table: :roles_customers
  one_to_many :sessions, class: "Suma::Member::Session", order: Sequel.desc([:created_at, :id])

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

  def self.matches_allowlist?(customer, allowlist)
    return allowlist.any? do |pattern|
      File.fnmatch(pattern, customer.phone || "") || File.fnmatch(pattern, customer.email || "")
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

  def admin?
    return self.roles.include?(Suma::Role.admin_role)
  end

  def greeting
    return self.name.blank? ? "there" : self.name
  end

  def onboarded?
    return self.name.present? && self.legal_entity.address_id.present?
  end

  def onboarding_verified?
    return self.onboarding_verified_at ? true : false
  end

  def read_only_reason
    return "read_only_unverified" if self.onboarding_verified_at.nil?
    return "read_only_technical_error" if self.payment_account.nil?
    return "read_only_zero_balance" if self.payment_account.total_balance <= Money.new(0)
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

  def usable_payment_instruments
    bank_accounts = self.
      legal_entity.
      bank_accounts_dataset.
      usable.
      order(Sequel.desc(:created_at), :id).
      all
    return bank_accounts
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

  protected def new_password_matches?(unencrypted)
    existing_pw = BCrypt::Password.new(self.password_digest)
    new_pw = self.digest_password(unencrypted)
    return existing_pw == new_pw
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

  ### Soft-delete hook -- expire unused, unexpired reset codes and
  ### trigger an event on removal.

  #
  # :section: Sequel Validation
  #

  def validate
    super
    self.validates_presence(:phone)
    self.validates_unique(:phone)
    unless self.soft_deleted?
      self.validates_format(Suma::PhoneNumber::US::REGEXP, :phone, message: "is not an 11 digit US phone number")
    end
    return if self[:email].nil?
    self.validates_unique(:email)
    self.validates_operator(:==, self.email.downcase.strip, :email)
  end
end

# Table: customers
# ----------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at        | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at        | timestamp with time zone |
#  soft_deleted_at   | timestamp with time zone |
#  password_digest   | text                     | NOT NULL
#  opaque_id         | text                     | NOT NULL
#  email             | citext                   | NOT NULL
#  email_verified_at | timestamp with time zone |
#  phone             | text                     | NOT NULL
#  phone_verified_at | timestamp with time zone |
#  name              | text                     | NOT NULL DEFAULT ''::text
#  note              | text                     | NOT NULL DEFAULT ''::text
#  timezone          | text                     | NOT NULL DEFAULT 'America/Los_Angeles'::text
#  registered_env    | text                     | NOT NULL
#  legal_entity_id   | integer                  | NOT NULL
# Indexes:
#  customers_pkey      | PRIMARY KEY btree (id)
#  customers_email_key | UNIQUE btree (email)
#  customers_phone_key | UNIQUE btree (phone)
# Check constraints:
#  lowercase_nospace_email | (email::text = btrim(lower(email::text)))
#  numeric_phone           | (phone ~ '^[0-9]{11,15}$'::text)
# Foreign key constraints:
#  customers_legal_entity_id_fkey | (legal_entity_id) REFERENCES legal_entities(id)
# Referenced By:
#  customer_journeys              | customer_journeys_customer_id_fkey              | (customer_id) REFERENCES customers(id) ON DELETE CASCADE
#  customer_linked_legal_entities | customer_linked_legal_entities_customer_id_fkey | (customer_id) REFERENCES customers(id)
#  customer_reset_codes           | customer_reset_codes_customer_id_fkey           | (customer_id) REFERENCES customers(id) ON DELETE CASCADE
#  customer_sessions              | customer_sessions_customer_id_fkey              | (customer_id) REFERENCES customers(id) ON DELETE CASCADE
#  message_deliveries             | message_deliveries_recipient_id_fkey            | (recipient_id) REFERENCES customers(id) ON DELETE SET NULL
#  roles_customers                | roles_customers_customer_id_fkey                | (customer_id) REFERENCES customers(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------
