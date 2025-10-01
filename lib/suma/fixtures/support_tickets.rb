# frozen_string_literal: true

require "suma/support/ticket"

module Suma::Fixtures::SupportTickets
  extend Suma::Fixtures

  fixtured_class Suma::Support::Ticket

  base :support_ticket do
    self.subject ||= Faker::Lorem.sentence
    self.body ||= Faker::Lorem.paragraph
  end
end
