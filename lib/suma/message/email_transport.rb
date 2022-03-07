# frozen_string_literal: true

require "suma/message/transport"

class Suma::Message::EmailTransport < Suma::Message::Transport
  include Appydays::Loggable

  register_transport(:email)

  def type
    return :email
  end

  def service
    return "none"
  end

  def supports_layout?
    false
  end

  def recipient(to)
    return Suma::Message::Recipient.new(to.name, to) if to.is_a?(Suma::Customer)
    return Suma::Message::Recipient.new(to, nil)
  end

  def allowlisted?(_delivery)
    return false
  end

  def send!(_delivery)
    raise "Email transport is not hooked up yet"
  end

  def add_bodies(delivery, content)
    bodies = []
    bodies << delivery.add_body(content: content[:subject], mediatype: "subject")
    bodies << delivery.add_body(content:, mediatype: "text/plain")
    bodies << delivery.add_body(content:, mediatype: "text/html")
    return bodies
  end
end
