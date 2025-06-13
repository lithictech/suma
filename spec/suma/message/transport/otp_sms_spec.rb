# frozen_string_literal: true

require "suma/message"

RSpec.describe Suma::Message::Transport::OtpSms, :db, reset_configuration: Suma::Message::Transport::Sms do
  before(:each) do
    Suma::Message::Transport::Sms.allowlist = ["*"]
  end

  describe "allowlisted?" do
    it "returns true if allowlisted" do
      Suma::Message::Transport::Sms.allowlist = ["1404*"]
      inst = described_class.new
      expect(inst).to be_allowlisted(Suma::Fixtures.message_delivery.sms("404-555-0128").instance)
      expect(inst).to_not be_allowlisted(Suma::Fixtures.message_delivery.sms("454-555-0128").instance)
      expect(inst).to_not be_allowlisted(Suma::Fixtures.message_delivery.sms("invalid").instance)
    end
  end

  describe "send!" do
    let(:delivery_fac) { Suma::Fixtures.message_delivery(template: "verification", template_language: "es") }

    it "sends verification messages via twilio verify" do
      req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
        with(body: {"Channel" => "sms", "CustomCode" => "12345", "To" => "+15554443210", "Locale" => "es"}).
        to_return(status: 200, body: load_fixture_data("twilio/post_verification", raw: true))
      delivery = delivery_fac.sms("+15554443210", "12345").create
      result = described_class.new.send!(delivery)
      expect(result).to eq("VE123-1")
      expect(req).to have_been_made
    end

    it "raises error if formatted phone is nil" do
      delivery = Suma::Fixtures.message_delivery.sms("invalid").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(/could not format/i)
    end

    it "raises undeliverable if the phone number is not allowlisted" do
      Suma::Message::Transport::Sms.allowlist = []
      sms = described_class.new
      delivery = Suma::Fixtures.message_delivery.sms("404-555-0128").create
      expect do
        sms.send!(delivery)
      end.to raise_error(Suma::Message::UndeliverableRecipient, /not allowlisted/)
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
      expect(described_class.new.recipient("5551112222")).to have_attributes(to: "5551112222", member: nil)
    end
  end
end
