# frozen_string_literal: true

require "suma/admin_linked"
require "suma/has_activity_audit"
require "suma/postgres/model"

class Suma::Organization::Membership < Suma::Postgres::Model(:organization_memberships)
  include Suma::AdminLinked
  include Suma::HasActivityAudit
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :verified_organization, class: "Suma::Organization"
  many_to_one :former_organization, class: "Suma::Organization"
  many_to_one :member, class: "Suma::Member"
  one_to_one :verification, class: "Suma::Organization::Membership::Verification"

  class << self
    # When set, do not create a Vrification object for unverified memberships on create/update.
    # Generally, this should only be used when fixturing verifications
    # to avoid automatically creating a membership, which would create a verification,
    # just to throw it away.
    attr_accessor :disable_auto_verification_creation
  end
  dataset_module do
    def verified = self.exclude(verified_organization_id: nil)
  end

  def verified? = !self.verified_organization_id.nil?
  def unverified? = self.unverified_organization_name.to_s != ""
  def removed? = !self.former_organization_id.nil?

  def organization_label
    return self.verified_organization&.name || self.former_organization&.name || self.unverified_organization_name
  end

  def lookup_organization_field(m, default=nil)
    return self.verified_organization&.send(m) ||
        self.former_organization&.send(m) ||
        self.matched_organization&.send(m) ||
        default
  end

  def organization_verification_email = lookup_organization_field(:membership_verification_email, "")

  def verified_organization_id=(id)
    self.unverified_organization_name = nil unless id.nil?
    self[:verified_organization_id] = id
  end

  def remove_from_organization(now: Time.now)
    raise Suma::InvalidPrecondition, "verified_organization must be set" if self.verified_organization_id.nil?
    self.former_organization = self.verified_organization
    self.formerly_in_organization_at = now
    self.verified_organization = nil
    return self.former_organization
  end

  def membership_type
    return "verified" if self.verified_organization
    return "removed" if self.former_organization
    return "unverified"
  end

  def matched_organization
    return nil unless self.unverified?
    return Suma::Organization[name: self.unverified_organization_name]
  end

  def rel_admin_link = "/membership/#{self.id}"

  def hybrid_search_fields
    return [
      self.verified? && :verified_organization,
      self.unverified? && :unverified_organization_name,
      :member,
    ]
  end

  def hybrid_search_facts
    return [
      self.verified? && "I am verified.",
      self.unverified? && "I am unverified.",
    ]
  end

  def after_save
    r = super
    # When a membership is verified, we want to make sure the member is also onboarding verified.
    # We must do this as part of a single backend operation, not an async job, since we want to make sure
    # an API request that verifies a membership also verifies the user, otherwise they can be in
    # an inconsistent state. Even though this inconsistent state isn't exactly wrong
    # (and we shouldn't assume it's true, since onboarding and membership verifications are different things),
    # it's so important for admins (and to some degree, common expectations)
    # that we enforce it here and not elsewhere (like in an API endpoint).
    if self.verified?
      self.member.onboarding_verified = true
      self.member.save_changes
    end
    if self.unverified? && !self.class.disable_auto_verification_creation
      self.verification ||= Suma::Organization::Membership::Verification.create(membership: self)
    end
    return r
  end
end

# Table: organization_memberships
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                           | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                   | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                   | timestamp with time zone |
#  verified_organization_id     | integer                  |
#  unverified_organization_name | text                     |
#  member_id                    | integer                  |
#  search_content               | text                     |
#  search_embedding             | vector(384)              |
#  search_hash                  | text                     |
#  former_organization_id       | integer                  |
#  formerly_in_organization_at  | timestamp with time zone |
# Indexes:
#  organization_memberships_pkey                           | PRIMARY KEY btree (id)
#  unique_member_membership_in_verified_organization       | UNIQUE btree (member_id, verified_organization_id)
#  organization_memberships_former_organization_id_index   | btree (former_organization_id)
#  organization_memberships_member_id_index                | btree (member_id)
#  organization_memberships_search_content_tsvector_index  | gin (to_tsvector('english'::regconfig, search_content))
#  organization_memberships_verified_organization_id_index | btree (verified_organization_id)
# Check constraints:
#  unambiguous_former_organization | (former_organization_id IS NULL AND formerly_in_organization_at IS NULL OR former_organization_id IS NOT NULL AND formerly_in_organization_at IS NOT NULL)
#  unambiguous_verification_status | (verified_organization_id IS NOT NULL AND former_organization_id IS NULL AND unverified_organization_name IS NULL OR verified_organization_id IS NULL AND former_organization_id IS NOT NULL AND unverified_organization_name IS NULL OR verified_organization_id IS NULL AND former_organization_id IS NULL AND unverified_organization_name IS NOT NULL)
# Foreign key constraints:
#  organization_memberships_former_organization_id_fkey   | (former_organization_id) REFERENCES organizations(id)
#  organization_memberships_member_id_fkey                | (member_id) REFERENCES members(id)
#  organization_memberships_verified_organization_id_fkey | (verified_organization_id) REFERENCES organizations(id)
# Referenced By:
#  organization_membership_verifications | organization_membership_verifications_membership_id_fkey | (membership_id) REFERENCES organization_memberships(id)
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
