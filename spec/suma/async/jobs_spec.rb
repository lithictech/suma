# frozen_string_literal: true

require "suma/async"
require "suma/messages/specs"
require "rspec/eventually"

RSpec.describe "suma async jobs", :async, :db, :do_not_defer_events, :no_transaction_check do
  before(:all) do
    Suma::Async.setup_tests
  end

  describe "EnsureDefaultCustomerLedgersOnCreate" do
    it "creates ledgers" do
      expect do
        Suma::Fixtures.customer.create
      end.to perform_async_job(Suma::Async::EnsureDefaultCustomerLedgersOnCreate)

      c = Suma::Customer.last
      expect(c).to have_attributes(payment_account: be_present)
      expect(c.payment_account.ledgers).to have_length(1)
    end
  end

  describe "MessageDispatched", messaging: true do
    it "sends the delivery on create" do
      email = "wibble@lithic.tech"

      expect do
        Suma::Messages::Testers::Basic.new.dispatch(email)
      end.to perform_async_job(Suma::Async::MessageDispatched)

      expect(Suma::Message::Delivery).to have_row(to: email).
        with_attributes(transport_message_id: be_a(String))
    end
  end

  describe "ResetCodeCreateDispatch" do
    it "sends an sms for an sms reset code" do
      customer = Suma::Fixtures.customer(phone: "12223334444").create
      expect do
        customer.add_reset_code(token: "12345", transport: "sms")
      end.to perform_async_job(Suma::Async::ResetCodeCreateDispatch)

      expect(Suma::Message::Delivery.all).to contain_exactly(
        have_attributes(
          template: "verification",
          transport_type: "sms",
          to: "12223334444",
          bodies: contain_exactly(
            have_attributes(content: "Your Suma verification code is: 12345"),
          ),
        ),
      )
    end
  end
end
