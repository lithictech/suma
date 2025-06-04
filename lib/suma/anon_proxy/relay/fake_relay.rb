# frozen_string_literal: true

class Suma::AnonProxy::Relay::FakeRelay < Suma::AnonProxy::Relay
  class_attribute :provisioned_external_id

  def webhookdb_table = nil
  def parse_message(row) = Suma::AnonProxy::ParsedMessage.new(**row)
end
