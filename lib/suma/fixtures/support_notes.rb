# frozen_string_literal: true

require "suma/support/note"

module Suma::Fixtures::SupportNotes
  extend Suma::Fixtures

  fixtured_class Suma::Support::Note

  base :support_note do
    self.content ||= Faker::Lorem.paragraph
    self.created_at ||= Time.now
  end

  before_saving do |instance|
    instance.creator ||= Suma::Fixtures.member.create
    instance
  end

  decorator :annotate, presave: true do |*objs|
    objs.each { |o| o.add_note(self) }
  end
end
