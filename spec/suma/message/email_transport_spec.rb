# frozen_string_literal: true

require "suma/message"

RSpec.describe Suma::Message::EmailTransport, :db do
  describe "add_bodies" do
    it "renders subject, plain text, and HTML/inlined CSS bodies" do
      delivery = Suma::Fixtures.message_delivery.via(:email).create
      described_class.new.add_bodies(delivery, Suma::Message::Rendering.new("<p>hi</p>", subject: "Hello"))

      expect(delivery.bodies).to contain_exactly(
        have_attributes(content: "Hello", mediatype: "subject"),
        have_attributes(content: "hi", mediatype: "text/plain"),
        have_attributes(content: include("<html><body><p>hi</p>"), mediatype: "text/html"),
      )
    end

    it "errors if content is not a string or has no subject" do
      delivery = Suma::Fixtures.message_delivery.via(:email).create
      xport = described_class.new
      expect do
        xport.add_bodies(delivery, "hello")
      end.to raise_error(/missing a subject/)

      expect do
        xport.add_bodies(delivery, Suma::Message::Rendering.new("<p>hi</p>"))
      end.to raise_error(/missing a subject/)
    end
  end

  describe "recipient" do
    it "raises if the member has no email" do
      u = Suma::Fixtures.member.create(email: nil)
      expect { described_class.new.recipient(u) }.to raise_error(Suma::InvalidPrecondition, /email/)
    end

    it "uses the members email for :to" do
      u = Suma::Fixtures.member.create(email: "x@y.z")
      expect(described_class.new.recipient(u)).to have_attributes(to: "x@y.z", member: u)
    end

    it "uses the value for :to if not a member" do
      expect(described_class.new.recipient("f@b.c")).to have_attributes(to: "f@b.c", member: nil)
    end
  end
end
