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
        row = coercers.map do |c|
          v = c[m]
          if v.is_a?(String)
            # If the string starts with an equal sign, add 'UNSAFE' before it,
            # so spreadsheet programs will not evaluate it as a macro
            # which can be confusing (name of "=1+1" would appear as "2")
            # and potentially dangerous. A space or tab char is not enough
            # to prevent macros for some csv software like Numbers app on mac.
            v = "UNSAFE#{v}" if v.match?(/^\s*=/)
          end
          v
        end
        csv << row
      end
    end
    return got
  end
end
