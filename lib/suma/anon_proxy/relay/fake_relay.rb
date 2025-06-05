# frozen_string_literal: true

class Suma::AnonProxy::Relay::FakeRelay < Suma::AnonProxy::Relay
  class_attribute :provisioned_external_id

  def self.deprovision(_addr) = nil

  def webhookdb_dataset = nil
  def parse_message(row) = Suma::AnonProxy::ParsedMessage.new(**row)
  def deprovision(addr) = self.class.deprovision(addr)
end
