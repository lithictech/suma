# frozen_string_literal: true

require "suma/anon_proxy"
require "suma/simple_registry"

module Suma::AnonProxy::Email
  extend Suma::SimpleRegistry

  # def self.dispatch(from:, to:, body:)
  #   user = self.lookup_member(to)
  #   if from == "lime"
  #     # forward sms
  #   end
  # end
  #
  # def self.lookup_member(to)
  #   id = to[1..].split("@").first
  #   m = Suma::Member[id: id.to_i]
  #   return m if m
  #   raise Suma::InvalidPostcondition, "no valid member #{id} parsed from #{to}"
  # end
  #
  # def self.to_email(member)
  #   return "m#{member.id}@#{Suma::AnonProxy.email_server}"
  # end
  class Provider
    # @return [String]
    def provision(_member) = raise NotImplementedError
  end

  class PostmarkProvider < Provider
    def provision(member)
      return "m#{member.id}@#{Suma::AnonProxy.postmark_email_server}"
    end
  end

  class FakeProvider < Provider
    def provision(member)
      return "u#{member.id}@example.com"
    end
  end

  Suma::AnonProxy::Email.register("postmark", PostmarkProvider)
  Suma::AnonProxy::Email.register("fake", FakeProvider)

  # @return [String]
  def self.active_provider_key = Suma::AnonProxy.email_provider
  # @return [Suma::AnonProxy::Email::Provider]
  def self.active_provider = self.lookup!(self.active_provider_key)
end
