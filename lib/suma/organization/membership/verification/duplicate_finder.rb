# frozen_string_literal: true

class Suma::Organization::Membership::Verification::DuplicateFinder
  HIGH = :high
  MED = :medium
  LOW = :low
  CACHE_KEY = "v1"

  def self.chance_value(x)
    x = x.to_sym
    return 1 if x == HIGH
    return 0.5 if x == MED
    return 0
  end

  # Return SerializedMatches from the cache if possible,
  # or run the duplicate finder if needed (and save results to cache).
  def self.lookup_matches(verification)
    must_run = verification.cached_duplicates_key != CACHE_KEY
    if must_run
      matches = self.new(verification).run.matches
      verification.cached_duplicates_key = CACHE_KEY
      verification.cached_duplicates = matches.map(&:as_serialized).as_json
      verification.save_changes
    end
    return verification.cached_duplicates.map { |d| SerializedMatch.new(**d) }
  end

  class Match < Suma::TypedStruct
    attr_accessor :member,
                  :organization_name,
                  :verification,
                  :chance,
                  :reason

    def initialize(**)
      super
      return unless self.verification
      self.member = self.verification.membership.member
      self.organization_name = self.verification.membership.organization_label
    end

    def as_serialized
      return SerializedMatch.new(
        member_id: self.member.id,
        member_name: self.member.name,
        member_phone: self.member.us_phone,
        member_email: self.member.email,
        member_admin_link: self.member.admin_link,
        organization_name: self.organization_name,
        verification_id: self.verification&.id,
        chance: self.chance,
        reason: self.reason,
      )
    end
  end

  class SerializedMatch < Suma::TypedStruct
    attr_accessor :member_id,
                  :member_name,
                  :member_phone,
                  :member_email,
                  :member_admin_link,
                  :organization_name,
                  :verification_id,
                  :chance,
                  :reason
  end

  attr_reader :matches

  def initialize(verification)
    @verification = verification
    @member = @verification.membership.member
    @matches = nil
  end

  def run
    @matches = []
    search_account_numbers
    search_members
    search_addresses
    return self
  end

  def search_account_numbers
    ac = @verification.account_number
    return if ac.blank?
    sames = Suma::Organization::Membership::Verification.
      with_encrypted_value(:account_number, ac).
      exclude(id: @verification.id).
      all
    sames.each do |v|
      @matches << Match.new(verification: v, chance: HIGH, reason: :account_number)
    end
  end

  # Adjust this as needed; some decent fuzziness is probably fine.
  NAME_SIMILARITY = 0.7

  def search_members
    name_match = Sequel.function(:similarity, :name, @member.name) > NAME_SIMILARITY
    phone_match = Sequel[@member.phone => Sequel.function(:ANY, :previous_phones)]
    email_match = Sequel[@member.email => Sequel.function(:ANY, :previous_emails)]
    sames = Suma::Member.
      select_append(
        name_match.as(:name_match),
        phone_match.as(:phone_match),
        email_match.as(:email_match),
      ).
      where(name_match | phone_match | email_match).
      exclude(id: @member.id).
      all
    sames.each do |m|
      if m[:phone_match]
        reason = :phone
        chance = :high
      elsif m[:email_match]
        reason = :email
        chance = :high
      else
        chance = m.name == @member.name ? HIGH : MED
        reason = :name
      end
      @matches << Match.new(member: m, chance:, reason:)
    end
  end

  # Because of city/state/country, we need to use a high threshold
  ADDRESS_SIMILARITY = 0.9
  def search_addresses
    return unless @member.legal_entity.address
    address_same = Sequel[legal_entity: Suma::LegalEntity.where(address: @member.legal_entity.address)]
    similar_address_text = Sequel.function(
      :similarity,
      @member.legal_entity.address.one_line_address,
      Sequel.function(:concat, :address1, ", ", :address2, ", ", :city, ", ", :state_or_province, ", ", :postal_code,
                      ", ", :country,),
    )
    address_similar = Sequel[
      legal_entity: Suma::LegalEntity.where(address: Suma::Address.where(similar_address_text > ADDRESS_SIMILARITY)),
    ]
    sames_ds = Suma::Member.
      select_append(
        address_same.as(:address_same),
        address_similar.as(:address_like),
      ).
      where(address_same | address_similar).
      exclude(id: @member.id)
    sames = sames_ds.all
    sames.each do |m|
      chance = if m[:address_same]
                 HIGH
      elsif @member.legal_entity.address.address2.upcase == m.legal_entity.address.address2.upcase
        MED
      else
        LOW
      end
      @matches << Match.new(member: m, chance:, reason: :address)
    end
  end
end

# Table: organization_membership_verification_audit_logs
# -----------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id              | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  at              | timestamp with time zone | NOT NULL
#  event           | text                     | NOT NULL
#  to_state        | text                     | NOT NULL
#  from_state      | text                     | NOT NULL
#  reason          | text                     | NOT NULL DEFAULT ''::text
#  messages        | jsonb                    | NOT NULL DEFAULT '[]'::jsonb
#  verification_id | integer                  | NOT NULL
#  actor_id        | integer                  |
# Indexes:
#  organization_membership_verification_audit_logs_pkey            | PRIMARY KEY btree (id)
#  organization_membership_verification_audit_logs_verification_id | btree (verification_id)
# Foreign key constraints:
#  organization_membership_verification_audit_logs_actor_id_fkey   | (actor_id) REFERENCES members(id) ON DELETE SET NULL
#  organization_membership_verification_audit_verification_id_fkey | (verification_id) REFERENCES organization_membership_verifications(id) ON DELETE CASCADE
# -----------------------------------------------------------------------------------------------------------------------------------------------------------
