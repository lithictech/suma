# frozen_string_literal: true

class Suma::Member::Exporter
  def initialize(dataset)
    @dataset = dataset
  end

  HEADERS = [
    ["Id", ->(m) { m.id }],
    ["Name", ->(m) { m.name }],
    ["Lang", ->(m) { m.message_preferences&.preferred_language }],
    ["Channel", ->(m) { m.referral&.channel }],
    ["Event", ->(m) { m.referral&.event_name }],
    ["Phone", lambda { |m|
                m.soft_deleted? ? m.phone : Suma::PhoneNumber::US.format(m.phone)
              },],
    ["IntlPhone", ->(m) { m.phone }],
    ["Email", ->(m) { m.email }],
    ["Address1", ->(m) { m.legal_entity.address&.address1 }],
    ["Address2", ->(m) { m.legal_entity.address&.address2 }],
    ["City", ->(m) { m.legal_entity.address&.city }],
    ["State", ->(m) { m.legal_entity.address&.state_or_province }],
    ["Zip", ->(m) { m.legal_entity.address&.postal_code }],
    ["Country", ->(m) { m.legal_entity.address&.country }],
    ["Verified", ->(m) { m.onboarding_verified_at ? true : false }],
    ["Eligibility Constraints", ->(m) { m.verified_eligibility_constraints.map(&:name).join("|") }],
    ["Deleted", ->(m) { m.soft_deleted_at ? true : false }],
    ["Timezone", ->(m) { m.timezone }],
  ].freeze

  def to_csv
    coercers = HEADERS.map(&:second)
    got = CSV.generate do |csv|
      csv << HEADERS.map(&:first)
      @dataset.paged_each do |m|
        row = coercers.map { |c| c[m] }
        csv << row
      end
    end
    return got
  end
end
