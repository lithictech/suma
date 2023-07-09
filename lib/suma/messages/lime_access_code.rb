# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::LimeAccessCode < Suma::Message::Template
  def self.fixtured(recipient)
    token = SecureRandom.hex(4)
    return self.new(recipient, token, "https://magiclink?token=#{token}")
  end

  def initialize(recipient, magic_link, token)
    @recipient = recipient
    @magic_link = magic_link
    @token = token
    super()
  end

  def template_folder = "anon_proxy"

  def liquid_drops
    return super.merge(
      magic_link: @magic_link,
      token: @token,
    )
  end

  def localized? = true
end
