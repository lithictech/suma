# frozen_string_literal: true

require "faker"

require "suma/fixtures"
require "suma/message/delivery"

module Suma::Fixtures::MessageDeliveries
  extend Suma::Fixtures

  fixtured_class Suma::Message::Delivery

  depends_on(:members)

  base :message_delivery do
    self.template ||= "fixture"
    self.transport_type ||= "fake"
    self.to ||= "fixture-to"
  end

  before_saving do |instance|
    instance.carrier_key ||= instance.transport!.carrier.key
    instance
  end

  decorator :email, presave: true do |to=nil, content=nil|
    content ||= Faker::Lorem.paragraph
    self.transport_type = "email"
    self.to = to || self.recipient&.email || Faker::Internet.email
    self.add_body(mediatype: "subject", content: Faker::Lorem.sentence)
    self.add_body(mediatype: "text/plain", content:)
    self.add_body(mediatype: "text/html",
                  content: "<html><body><p>#{content}</p><p><strong>#{content}</strong></p></body></html>",)
  end

  decorator :sms, presave: true do |to=nil, content=nil|
    content ||= Faker::Lorem.paragraph
    self.transport_type = "sms"
    self.to = to || self.recipient&.phone || Faker::PhoneNumber.cell_phone
    self.add_body(mediatype: "text/plain", content:)
  end

  decorator :to do |recipient=nil|
    recipient = self.transport!.recipient(recipient)
    self.to = recipient.to
    self.recipient = recipient.member
  end

  decorator :with_recipient do |member={}|
    member = Suma::Fixtures.member.create(member) unless member.is_a?(Suma::Member)
    self.recipient = member
  end

  decorator :with_body, presave: true do |body={}|
    body[:mediatype] ||= Faker::Lorem.word
    body[:content] ||= Faker::Lorem.paragraph
    self.add_body(body)
  end

  decorator :via do |transport|
    self.transport_type = transport
    self.to = self.transport!.recipient(self.recipient).to if self.recipient
  end

  decorator :sent do |at=nil|
    at ||= Time.now
    self.sent_at = at
    self.transport_message_id = "fixtured-#{SecureRandom.hex(6)}"
  end

  decorator :aborted do |at=nil|
    at ||= Time.now
    self.aborted_at = at
  end

  decorator :extra do |k, v|
    self.extra_fields[k.to_s] = v
  end

  decorator :sent_to_verification do |verification_sid="VE#{SecureRandom.hex(4)}"|
    xport = Suma::Message::Transport.registry_create!(:otp_sms)
    self.transport_type = xport.type
    self.carrier_key = xport.carrier.key
    self.template = "verification"
    self.transport_message_id = xport.carrier.encode_message_id(verification_sid, "1")
  end
end
