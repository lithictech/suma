# frozen_string_literal: true

require "suma/message"
require "suma/messages/specs"

RSpec.describe "Suma::Message", :db, :messaging do
  let(:described_class) { Suma::Message }
  let(:testers) { Suma::Messages::Testers }

  describe "dispatch" do
    let(:basic) { Suma::Messages::Testers::Basic.new }
    it "creates an undelivered message to the given recipient", messaging: false do
      recipient = Suma::Fixtures.member.create
      delivery = basic.dispatch(recipient)

      expect(delivery).to have_attributes(
        template: "specs/basic",
        transport_type: "sms",
        carrier_key: "signalwire",
        transport_message_id: nil,
        sent_at: nil,
        to: recipient.phone,
        recipient:,
        sensitive: false,
      )
      expect(delivery.bodies).to have_length(be >= 1)
    end

    it "can send a message to a bare email" do
      delivery = basic.dispatch("member@lithic.tech")
      expect(delivery).to have_attributes(
        to: "member@lithic.tech",
        recipient: nil,
      )
    end

    it "can specify a different transport" do
      delivery = basic.dispatch("member@lithic.tech", transport: :fake)
      expect(delivery).to have_attributes(
        transport_type: "fake",
        carrier_key: "noop",
      )
    end

    it "errors if the transport is invalid", messaging: false do
      expect do
        basic.dispatch("member@lithic.tech", transport: :fake2)
      end.to raise_error(Suma::SimpleRegistry::Unregistered)
    end

    it "renders bodies using the specified transport" do
      delivery = basic.dispatch("member@lithic.tech", transport: :fake)
      expect(delivery.bodies).to have_length(1)
      expect(delivery.bodies.first).to have_attributes(content: match("test message to member@lithic.tech"))
    end

    it "sets the delivery as sensitive if the template is sensitive" do
      tmpl = Suma::Messages::Testers::Sensitive.new
      delivery = tmpl.dispatch("member@lithic.tech", transport: :sms)
      expect(delivery).to have_attributes(sensitive: true)
    end

    it "errors if no language is set and the template supports localization" do
      tmpl = Suma::Messages::Testers::Localized.new
      expect do
        tmpl.dispatch("member@lithic.tech", transport: :sms)
      end.to raise_error(Suma::Message::LanguageNotSetError)
    end

    describe "when the template supports localization" do
      it "loads the static string" do
        tmpl = Suma::Messages::Testers::Localized.new
        tmpl.language = "es"
        Suma::Fixtures.static_string.
          message(tmpl, :sms).
          text("", es: "spanish message").
          create
        delivery = tmpl.dispatch("member@lithic.tech", transport: :sms)
        expect(delivery).to have_attributes(template_language: "es")
        expect(delivery.bodies).to contain_exactly(have_attributes(content: match("spanish message")))
      end

      it "errors if the static string localized content is blank" do
        tmpl = Suma::Messages::Testers::Localized.new
        tmpl.language = "es"
        Suma::Fixtures.static_string.
          message(tmpl, :sms).
          create
        expect do
          tmpl.dispatch("member@lithic.tech", transport: :sms)
        end.to raise_error(Suma::Message::MissingTemplateError, /Message blank/)
      end

      it "errors if there is no static string row" do
        tmpl = Suma::Messages::Testers::Localized.new
        tmpl.language = "es"
        expect do
          tmpl.dispatch("member@lithic.tech", transport: :sms)
        end.to raise_error(Suma::Message::MissingTemplateError, /No static string row/)
      end

      it "errors if the language is not set" do
        tmpl = Suma::Messages::Testers::Localized.new
        expect do
          tmpl.dispatch("member@lithic.tech", transport: :sms)
        end.to raise_error(Suma::Message::LanguageNotSetError)
      end
    end
  end

  describe "rendering" do
    let(:recipient) { Suma::Message::Recipient.new("member@lithic.tech", nil, nil) }

    it "errors if a template for the specified transport does not exist" do
      expect do
        tmpl = testers::Nonextant.new
        Suma::Message.render(tmpl, :fake, recipient)
      end.to raise_error(Suma::Message::MissingTemplateError)
    end

    it "renders the template using the given attributes" do
      tmpl = testers::WithField.new(2)
      r = Suma::Message.render(tmpl, :fake, recipient)
      expect(r.contents.strip).to eq("test message to member@lithic.tech, field 2")
    end

    it "renders strictly" do
      expect do
        tmpl = testers::MissingField.new
        Suma::Message.render(tmpl, :fake, recipient)
      end.to raise_error(Liquid::UndefinedVariable)
    end

    it "exposes variables from the template" do
      tmpl = testers::WithField.new(2)
      r = Suma::Message.render(tmpl, :email, recipient)
      expect(r[:subject]).to eq("subject with field 2 to member@lithic.tech")
    end

    it "can use includes" do
      tmpl = testers::WithInclude.new
      r = Suma::Message.render(tmpl, :email, recipient)
      expect(r.contents.strip).to eq("field before is 3. including: partial has field of 3")
    end

    it "can use partial" do
      tmpl = testers::WithPartial.new
      r = Suma::Message.render(tmpl, :email, recipient)
      expect(r.contents).to include("Suma</p>")
    end

    it "can use layout" do
      tmpl = testers::WithLayout.new
      r = Suma::Message.render(tmpl, :email, recipient)
      expect(r.contents.strip).to start_with("<!DOCTYPE html")
      expect(r.contents).to include("email to")
      expect(r.contents.strip).to end_with("</html>")
    end

    it "provides the member, environment, and any additional drops" do
      tmpl = testers::DropsTester.new
      r = Suma::Message.render(tmpl, :fake, recipient)
      expect(r.contents).to eq("test message to member@lithic.tech\n")
    end

    it "has filters available, including requiring liquifaction" do
      tmpl = testers::WithFilters.new(str: "solid_snake", amount: Money.new(123, "USD"))
      r = Suma::Message.render(tmpl, :fake, recipient)
      expect(r.contents).to eq("Solid snake $1.23\n")
    end
  end

  describe "send_unsent" do
    it "sends unsent deliveries" do
      unsent = Suma::Fixtures.message_delivery.create
      sent = Suma::Fixtures.message_delivery.sent.create

      expect do
        Suma::Message.send_unsent
      end.to not_change { sent.refresh.sent_at }.and(
        change { unsent.refresh.sent_at }.from(nil),
      )
    end
  end
end
