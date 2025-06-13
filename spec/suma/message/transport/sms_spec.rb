# frozen_string_literal: true

require "suma/message"

RSpec.describe Suma::Message::Transport::Sms, :db, reset_configuration: Suma::Message::Transport::Sms do
  before(:each) do
    described_class.allowlist = ["*"]
  end

  describe "allowlisted?" do
    it "returns true if allowlisted" do
      inst = described_class.new
      inst.allowlist = ["1404*"]
      expect(inst).to be_allowlisted(Suma::Fixtures.message_delivery.sms("404-555-0128").instance)
      expect(inst).to_not be_allowlisted(Suma::Fixtures.message_delivery.sms("454-555-0128").instance)
      expect(inst).to_not be_allowlisted(Suma::Fixtures.message_delivery.sms("invalid").instance)
    end
  end

  describe "send!" do
    it "sends message via transport" do
      req = stub_signalwire_sms(sid: "SMXYZ").
        with(body: {"Body" => "hello", "From" => "+15554443333", "To" => "+15554443210"})
      delivery = Suma::Fixtures.message_delivery.sms("+15554443210", "hello").create
      result = described_class.new.send!(delivery)
      expect(result).to eq("SMXYZ")
      expect(req).to have_been_made
    end

    it "can override the from number using an extra field" do
      req = stub_signalwire_sms(sid: "SMXYZ").
        with(body: {"Body" => "hello", "From" => "+19998887777", "To" => "+15554443210"})
      delivery = Suma::Fixtures.message_delivery.sms("+15554443210", "hello").
        create(extra_fields: {"from" => "19998887777"})
      result = described_class.new.send!(delivery)
      expect(result).to eq("SMXYZ")
      expect(req).to have_been_made
    end

    it "formats the provided phone number" do
      req = stub_signalwire_sms.
        with(body: {"Body" => "hello", "From" => "+15554443333", "To" => "+15554443210"})
      delivery = Suma::Fixtures.message_delivery.sms("(555) 444-3210", "hello").create
      described_class.new.send!(delivery)
      expect(req).to have_been_made
    end

    it "raises error if to phone cannot be e164 formatted" do
      delivery = Suma::Fixtures.message_delivery.sms("invalid").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(Suma::PhoneNumber::BadFormat)
    end

    it "raises undeliverable if the phone number is not allowlisted" do
      delivery = Suma::Fixtures.message_delivery.sms("404-555-0128").create
      expect do
        sms = described_class.new
        sms.allowlist = []
        sms.send!(delivery)
      end.to raise_error(Suma::Message::UndeliverableRecipient, /not allowlisted/)
    end

    describe "with sms provider disabled", reset_configuration: described_class do
      before(:each) do
        described_class.provider_disabled = true
      end

      it "raises undeliverable" do
        delivery = Suma::Fixtures.message_delivery.sms("+15554443210", "hello").create
        expect do
          described_class.new.send!(delivery)
        end.to raise_error(Suma::Message::UndeliverableRecipient, /SMS provider disabled/)
      end
    end
  end

  describe "add_bodies" do
    it "renders plain text" do
      delivery = Suma::Fixtures.message_delivery.via(:sms).create
      described_class.new.add_bodies(delivery, Suma::Message::Rendering.new("hello"))
      expect(delivery.bodies).to contain_exactly(have_attributes(content: "hello", mediatype: "text/plain"))
    end
  end

  describe "recipient" do
    it "raises if the member has no phone" do
      u = Suma::Fixtures.member.instance
      u.phone = ""
      expect { described_class.new.recipient(u) }.to raise_error(Suma::InvalidPrecondition, /phone/)
    end

    it "uses the members phone for :to" do
      u = Suma::Fixtures.member.create
      expect(described_class.new.recipient(u)).to have_attributes(to: u.phone, member: u)
    end

    it "uses the value for :to if not a member" do
      expect(described_class.new.recipient("15551112222")).to have_attributes(
        to: "15551112222", member: nil, formatted_to: "(555) 111-2222",
      )
    end

    it "does not format the phone if not US" do
      expect(described_class.new.recipient("5552223333")).to have_attributes(
        to: "5552223333", member: nil, formatted_to: "5552223333",
      )
    end
  end
end
