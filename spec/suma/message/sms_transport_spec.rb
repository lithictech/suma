# frozen_string_literal: true

require "suma/message/sms_transport"

RSpec.describe Suma::Message::SmsTransport, :db, reset_configuration: Suma::Message::SmsTransport do
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

  describe "verification ID parsing" do
    it "errors for an unknown ID format" do
      expect do
        described_class.transport_message_id_to_verification_id("X-123-1")
      end.to raise_error(described_class::UnknownVerificationId)
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

    it "formats the provided phone number" do
      req = stub_signalwire_sms.
        with(body: {"Body" => "hello", "From" => "+15554443333", "To" => "+15554443210"})
      delivery = Suma::Fixtures.message_delivery.sms("(555) 444-3210", "hello").create
      described_class.new.send!(delivery)
      expect(req).to have_been_made
    end

    it "raises error if formatted phone is nil" do
      delivery = Suma::Fixtures.message_delivery.sms("invalid").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(/could not format/i)
    end

    it "raises undeliverable if the phone number is not allowlisted" do
      delivery = Suma::Fixtures.message_delivery.sms("404-555-0128").create
      expect do
        sms = described_class.new
        sms.allowlist = []
        sms.send!(delivery)
      end.to raise_error(Suma::Message::Transport::UndeliverableRecipient, /not allowlisted/)
    end

    it "raises undeliverable if the phone number is invalid" do
      req = stub_signalwire_sms(fixture: "signalwire/error_invalid_phone", status: 400)
      delivery = Suma::Fixtures.message_delivery.sms("(555) 444-3210", "hello").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(Suma::Message::Transport::UndeliverableRecipient, /signalwire_invalid_phone_number/)
      expect(req).to have_been_made
    end

    it "raises signalwire errors" do
      req = stub_signalwire_sms(body: "error", status: 500)
      delivery = Suma::Fixtures.message_delivery.sms("(555) 444-3210", "hello").create
      expect do
        described_class.new.send!(delivery)
      end.to raise_error(Twilio::REST::RestError, /HTTP 500/)
      expect(req).to have_been_made
    end

    describe "with the verification template" do
      let(:delivery_fac) { Suma::Fixtures.message_delivery(template: "verification", template_language: "es") }

      it "sends verification messages via twilio verify" do
        req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
          with(body: {"Channel" => "sms", "CustomCode" => "12345", "To" => "+15554443210", "Locale" => "es"}).
          to_return(status: 200, body: load_fixture_data("twilio/post_verification", raw: true))
        delivery = delivery_fac.sms("+15554443210", "Your suma verification code is: 12345").create
        result = described_class.new.send!(delivery)
        expect(result).to eq("TV-VE123-1")
        expect(req).to have_been_made
        expect(described_class.transport_message_id_to_verification_id(result)).to eq("VE123")
      end

      it "errors if the verification template is used but no code can be extracted" do
        delivery = delivery_fac.sms("+15554443210", "Your suma verification code is: abcd").create
        expect do
          described_class.new.send!(delivery)
        end.to raise_error(/Cannot extract/)
      end

      it "raises undeliverable if the phone number is invalid" do
        req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
          to_return(status: 400, body: load_fixture_data("twilio/error_invalid_phone", raw: true))
        delivery = delivery_fac.sms("+15554443210", "Your suma verification code is: 12345").create
        expect do
          described_class.new.send!(delivery)
        end.to raise_error(Suma::Message::Transport::UndeliverableRecipient, /twilio_invalid_phone_number/)
        expect(req).to have_been_made
      end

      it "raises other twilio errors" do
        req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
          to_return(status: 500, body: "error")
        delivery = delivery_fac.sms("+15554443210", "Your suma verification code is: 12345").create
        expect do
          described_class.new.send!(delivery)
        end.to raise_error(Twilio::REST::RestError, /HTTP 500/)
        expect(req).to have_been_made
      end
    end

    describe "with sms provider disabled", reset_configuration: described_class do
      before(:each) do
        described_class.provider_disabled = true
      end

      it "sends verification messages via twilio verify" do
        req = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications").
          to_return(status: 200, body: load_fixture_data("twilio/post_verification", raw: true))
        delivery = Suma::Fixtures.message_delivery.
          sms("+15554443210", "Your suma verification code is: 12345").
          create(template: "verification", template_language: "es")
        result = described_class.new.send!(delivery)
        expect(result).to eq("TV-VE123-1")
        expect(req).to have_been_made
      end

      it "raises undeliverable for other SMS" do
        delivery = Suma::Fixtures.message_delivery.sms("+15554443210", "hello").create
        expect do
          described_class.new.send!(delivery)
        end.to raise_error(Suma::Message::Transport::UndeliverableRecipient, /SMS provider disabled/)
      end
    end
  end

  describe "add_bodies" do
    it "renders plain text" do
      delivery = Suma::Fixtures.message_delivery.via(:sms).create
      described_class.new.add_bodies(delivery, Suma::Message::Rendering.new("hello"))
      expect(delivery.bodies).to contain_exactly(have_attributes(content: "hello", mediatype: "text/plain"))
    end

    it "errors if content is not set" do
      delivery = Suma::Fixtures.message_delivery.via(:sms).create
      xport = described_class.new
      expect do
        xport.add_bodies(delivery, "")
      end.to raise_error(/content is not set/i)
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
