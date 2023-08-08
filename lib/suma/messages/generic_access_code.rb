# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::GenericAccessCode < Suma::Message::Template
  def self.fixtured(recipient)
    token = SecureRandom.hex(4)
    return self.new(recipient, "RideABike", token)
  end

  def initialize(recipient, service, token)
    @recipient = recipient
    @service = service
    @token = token
    super()
  end

  def template_folder = "anon_proxy"

  def liquid_drops
    return super.merge(
      service: @service,
      token: @token,
    )
  end

  def localized? = true
end
