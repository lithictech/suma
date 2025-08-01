# frozen_string_literal: true

class Suma::Organization::Membership::Verification::DuplicateFinder
  CACHE_KEY = "v1"

  class Risk < Suma::TypedStruct
    attr_reader :name, :value
  end

  class Factor < Suma::TypedStruct
    attr_accessor :risk, :reason

    def initialize(**)
      super
      self.risk = Risk.new(**self.risk) unless self.risk.is_a?(Risk)
    end
  end

  HIGH = Risk.new(name: "high", value: 1)
  MEDIUM = Risk.new(name: "medium", value: 0.5)
  LOW = Risk.new(name: "low", value: 0.1)

  NAME = "name"
  CONTACT = "contact"
  ADDRESS = "address"
  ACCOUNT_NUMBER = "account_number"

  # Return SerializedMatches from the cache if possible,
  # or run the duplicate finder if needed (and save results to cache).
  def self.lookup_matches(verification, force: false)
    must_run = verification.cached_duplicates_key != CACHE_KEY || force
    if must_run
      matches = self.new(verification).run.matches
      verification.cached_duplicates_key = CACHE_KEY
      verification.cached_duplicates = matches.map(&:as_serialized).as_json
      verification.save_changes
    end
    return verification.cached_duplicates.map { |d| SerializedMatch.new(**d) }
  end

  class Match
    attr_accessor :member, :factors

    def initialize(member)
      self.member = member
      self.factors = []
    end

    def max_risk = self.factors.map(&:risk).max_by(&:value)

    def as_serialized
      return SerializedMatch.new(
        member_id: self.member.id,
        member_name: self.member.name,
        member_phone: self.member.us_phone,
        member_email: self.member.email,
        member_admin_link: self.member.admin_link,
        factors: self.factors,
      )
    end
  end

  class SerializedMatch < Suma::TypedStruct
    attr_accessor :member_id,
                  :member_name,
                  :member_phone,
                  :member_email,
                  :member_admin_link,
                  :factors

    def initialize(**)
      super
      self.factors = self.factors.map { |f| f.is_a?(Hash) ? Factor.new(**f) : f }
    end

    def max_risk = self.factors.map(&:risk).max_by(&:value)
  end

  def initialize(verification)
    @verification = verification
    @member = @verification.membership.member
    @matches_by_member_id = nil
  end

  def matches = @matches_by_member_id.values.sort_by { |m| m.max_risk.value }

  def run
    @matches_by_member_id = {}
    search_account_numbers
    search_members
    search_addresses
    return self
  end

  def add_match(member, risk, reason)
    m = @matches_by_member_id[member.id] ||= Match.new(member)
    m.factors << Factor.new(risk:, reason:)
  end

  def search_account_numbers
    ac = @verification.account_number
    return if ac.blank?
    sames = Suma::Organization::Membership::Verification.
      with_encrypted_value(:account_number, ac).
      exclude(id: @verification.id).
      all
    sames.each do |v|
      add_match(v.membership.member, HIGH, ACCOUNT_NUMBER)
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
      if m[:phone_match] || m[:email_match]
        reason = CONTACT
        risk = HIGH
      else
        risk = m.name == @member.name ? HIGH : MEDIUM
        reason = NAME
      end
      add_match(m, risk, reason)
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
      risk = if m[:address_same]
               HIGH
      elsif @member.legal_entity.address.address2.upcase == m.legal_entity.address.address2.upcase
        MEDIUM
      else
        LOW
      end
      add_match(m, risk, ADDRESS)
    end
  end
end
