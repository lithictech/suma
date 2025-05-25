# frozen_string_literal: true

class Suma::Member::RoleAccess
  class Invalid < KeyError; end

  READ = :read
  WRITE = :write
  # For normal users, to allow file upload through /v1/images
  UPLOAD_FILES = :upload_files
  # Can impersonate other members.
  IMPERSONATE = :impersonate
  # See and log into the admin app.
  ADMIN_ACCESS = :admin_access
  # Access members.
  ADMIN_MEMBERS = :admin_members
  # Access offering and product information.
  ADMIN_COMMERCE = :admin_commerce
  # Access payments (book, funding, refunds, etc) information.
  ADMIN_PAYMENTS = :admin_payments
  # Access sensitive messages, like verification codes.
  ADMIN_SENSITIVE_MESSAGES = :admin_sensitive_messages
  # Access privileged areas of admin, like creating new programs,
  # that most users do not need to do.
  ADMIN_MANAGEMENT = :admin_management

  KEYS = Set.new([
                   UPLOAD_FILES,
                   IMPERSONATE,
                   ADMIN_ACCESS,
                   ADMIN_MEMBERS,
                   ADMIN_COMMERCE,
                   ADMIN_PAYMENTS,
                   ADMIN_SENSITIVE_MESSAGES,
                   ADMIN_MANAGEMENT,
                 ]).freeze

  def upload_files = UPLOAD_FILES
  def impersonate = IMPERSONATE
  def admin_access = ADMIN_ACCESS
  def admin_members = ADMIN_MEMBERS
  def admin_commerce = ADMIN_COMMERCE
  def admin_payments = ADMIN_PAYMENTS
  def admin_sensitive_messages = ADMIN_SENSITIVE_MESSAGES
  def admin_management = ADMIN_MANAGEMENT

  def initialize(member)
    @member = member
    @features = {}
    # rubocop:disable Style/GuardClause, Style/IfUnlessModifier
    if member.roles.include?(Suma::Role.cache.admin)
      self.add_feature(UPLOAD_FILES, true, true)
      self.add_feature(IMPERSONATE, true, true)
      self.add_feature(ADMIN_ACCESS, true, true)
      self.add_feature(ADMIN_MEMBERS, true, true)
      self.add_feature(ADMIN_COMMERCE, true, true)
      self.add_feature(ADMIN_PAYMENTS, true, true)
      self.add_feature(ADMIN_SENSITIVE_MESSAGES, true, true)
      self.add_feature(ADMIN_MANAGEMENT, true, true)
    end
    if member.roles.include?(Suma::Role.cache.readonly_admin)
      self.add_feature(ADMIN_ACCESS, true, false)
      self.add_feature(ADMIN_MEMBERS, true, false)
      self.add_feature(ADMIN_COMMERCE, true, false)
      self.add_feature(ADMIN_PAYMENTS, true, false)
      self.add_feature(ADMIN_MANAGEMENT, true, false)
    end
    if member.roles.include?(Suma::Role.cache.noop_admin)
      self.add_feature(ADMIN_ACCESS, true, false)
    end
    if member.roles.include?(Suma::Role.cache.upload_files)
      self.add_feature(UPLOAD_FILES, true, true)
    end
    if member.roles.include?(Suma::Role.cache.onboarding_manager)
      self.add_feature(ADMIN_ACCESS, true, true)
      self.add_feature(ADMIN_MEMBERS, true, true)
    end
    if member.roles.include?(Suma::Role.cache.sensitive_messages)
      self.add_feature(ADMIN_SENSITIVE_MESSAGES, true, false)
    end
    # rubocop:enable Style/GuardClause, Style/IfUnlessModifier
  end

  def read?(key) = can?(READ, key)
  def write?(key) = can?(WRITE, key)

  # Return whether the given key can perform the given operation.
  # @param rw [:read,:write]
  # @param key [Symbol]
  def can?(rw, key)
    raise Invalid, "invalid action #{key}" unless KEYS.include?(key)
    a = @features[key]
    return false if a.nil?
    return a.include?(rw)
  end

  protected def add_feature(key, read, write)
    return unless read || write
    f = @features[key] ||= []
    f << READ if read
    f << WRITE if write
    f.uniq!
    f.sort!
  end

  def as_json = @features.as_json
  def to_json(*) = self.as_json.to_json(*)
end
