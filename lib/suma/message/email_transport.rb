# frozen_string_literal: true

require "premailer"

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
    if to.is_a?(Suma::Member)
      raise Suma::InvalidPrecondition, "Member[#{to.id}] has no email" if to.email.blank?
      return Suma::Message::Recipient.new(to.email, to)
    end
    return Suma::Message::Recipient.new(to, nil)
  end

  def allowlisted?(_delivery)
    return false
  end

  def send!(_delivery)
    raise NotImplementedError, "Email transport is not hooked up yet"
  end

  def add_bodies(delivery, content)
    pm = Premailer.new(
      content.to_s,
      with_html_string: true,
      warn_level: Premailer::Warnings::SAFE,
    )

    begin
      subject = content[:subject]
    rescue TypeError, NoMethodError
      subject = nil
    end

    raise ArgumentError, "content %p is missing a subject" % content unless subject

    bodies = []
    bodies << delivery.add_body(content: content[:subject], mediatype: "subject")
    bodies << delivery.add_body(content: pm.to_plain_text, mediatype: "text/plain")
    bodies << delivery.add_body(content: pm.to_inline_css, mediatype: "text/html")
    return bodies
  end
end
