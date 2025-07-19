# frozen_string_literal: true

require "suma/messages/order_confirmation"
require "suma/messages/single_value"
require "suma/messages/verification"

RSpec.describe Suma::Message, :db do
  describe "template fixturing" do
    let(:r) { Suma::Fixtures.member.create }

    it "can fixture OrderConfirmation" do
      tmpl = Suma::Messages::OrderConfirmation.fixtured(r)
      tmpl.language = "en"
      tmpl.dispatch(r, transport: :sms)
      expect(r.message_deliveries).to have_length(1)
      expect(r.message_deliveries.first.bodies.first.content).to eq("test confirmation (en)")
    end

    it "can fixture SingleValue" do
      tmpl = Suma::Messages::SingleValue.fixtured(r)
      tmpl.language = "en"
      tmpl.dispatch(r, transport: :sms)
      expect(r.message_deliveries).to have_length(1)
      expect(r.message_deliveries.first.bodies.first.content).to eq("test single value (en)")
    end

    it "can fixture Verification" do
      tmpl = Suma::Messages::Verification.fixtured(r)
      tmpl.language = "en"
      tmpl.dispatch(r, transport: :otp_sms)
      expect(r.message_deliveries).to have_length(1)
      expect(r.message_deliveries.first.bodies.first.content).to match(/\d+/)
    end
  end
end
