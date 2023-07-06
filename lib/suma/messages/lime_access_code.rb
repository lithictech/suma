# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::LimeAccessCode < Suma::Message::Template
  def self.fixtured(recipient)
    return self.new(recipient, SecureRandom.hex(4))
  end

  def initialize(recipient, token)
    @recipient = recipient
    @token = token
    super()
  end

  def template_folder = "anon_proxy"

  def liquid_drops
    return super.merge(
      token: @token,
    )
  end

  def localized? = true
end
