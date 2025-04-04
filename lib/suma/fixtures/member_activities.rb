# frozen_string_literal: true

require "suma"
require "suma/fixtures"
require "suma/member"

module Suma::Fixtures::MemberActivities
  extend Suma::Fixtures

  fixtured_class Suma::Member::Activity

  base :member_activity do
    self.message_name ||= Faker::NatoPhoneticAlphabet.code_word
    self.summary ||= "Fixtured activity"
    self.subject_type ||= "Fixtured"
    self.subject_id ||= Time.now.to_i
  end

  before_saving do |instance|
    instance.member ||= Suma::Fixtures.member.create
    instance
  end

  decorator :subject do |m|
    self.subject_type = m.class.name
    self.subject_id = m.id.to_s
  end
end
