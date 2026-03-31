# frozen_string_literal: true

require "suma/exporter"

class Suma::Member::Exporter < Suma::Exporter
  def headers
    return [
      ["Id", lambda(&:id)],
      ["Name", lambda(&:name)],
      ["Lang", ->(m) { m.message_preferences&.preferred_language }],
      ["Source", ->(m) { m.referral&.source }],
      ["Campaign", ->(m) { m.referral&.campaign }],
      ["Phone", lambda { |m|
                  m.soft_deleted? ? m.phone : Suma::PhoneNumber.format_display(m.phone)
                },],
      ["IntlPhone", lambda(&:phone)],
      ["Email", lambda(&:email)],
      ["Address1", ->(m) { m.legal_entity.address&.address1 }],
      ["Address2", ->(m) { m.legal_entity.address&.address2 }],
      ["City", ->(m) { m.legal_entity.address&.city }],
      ["State", ->(m) { m.legal_entity.address&.state_or_province }],
      ["Zip", ->(m) { m.legal_entity.address&.postal_code }],
      ["Country", ->(m) { m.legal_entity.address&.country }],
      ["Verified", ->(m) { m.onboarding_verified_at ? true : false }],
      ["Programs", ->(m) { m.eligible_programs(as_of: self.as_of).map { |pr| pr.name.en }.sort.join("|") }],
      ["Deleted", ->(m) { m.soft_deleted_at ? true : false }],
      ["Timezone", lambda(&:timezone)],
    ]
  end
end
