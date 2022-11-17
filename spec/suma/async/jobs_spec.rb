# frozen_string_literal: true

require "suma/async"
require "suma/messages/specs"
require "rspec/eventually"

RSpec.describe "suma async jobs", :async, :db, :do_not_defer_events, :no_transaction_check do
  before(:all) do
    Suma::Async.setup_tests
  end

  describe "AutomationTriggerRunner" do
    it "runs active automations" do
      active = Suma::Fixtures.automation_trigger.create
      active_mismatch_topic = Suma::Fixtures.automation_trigger.create(topic: "suma.z")
      inactive = Suma::Fixtures.automation_trigger.inactive.create
      expect(Suma::AutomationTrigger::Tester).to receive(:run).with(be === active, have_attributes(payload: [5, 6]))

      expect do
        Amigo.publish("suma.x", 5, 6)
      end.to perform_async_job(Suma::Async::AutomationTriggerRunner)
    end
  end

  describe "EnsureDefaultMemberLedgersOnCreate" do
    it "creates ledgers" do
      expect do
        Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::EnsureDefaultMemberLedgersOnCreate)

      c = Suma::Member.last
      expect(c).to have_attributes(payment_account: be_present)
      expect(c.payment_account.ledgers).to have_length(1)
    end
  end

  describe "FundingTransactionProcessor" do
    it "processes all created and collecting funding transactions" do
      created = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      created.strategy.set_response(:ready_to_collect_funds?, true)
      created.strategy.set_response(:collect_funds, true)
      created.strategy.set_response(:funds_cleared?, true)

      collecting = Suma::Fixtures.funding_transaction.with_fake_strategy.create(status: "collecting")
      collecting.strategy.set_response(:ready_to_collect_funds?, true)
      collecting.strategy.set_response(:collect_funds, false)
      collecting.strategy.set_response(:funds_cleared?, true)

      stuck = Suma::Fixtures.funding_transaction.with_fake_strategy.create
      stuck.strategy.set_response(:ready_to_collect_funds?, true)
      stuck.strategy.set_response(:collect_funds, true)
      stuck.strategy.set_response(:funds_cleared?, false)

      Suma::Async::FundingTransactionProcessor.new.perform

      # Was processed all the way through
      expect(created.refresh).to have_attributes(status: "cleared")
      expect(collecting.refresh).to have_attributes(status: "cleared")
      expect(stuck.refresh).to have_attributes(status: "collecting")
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

  describe "OrderConfirmation" do
    let!(:order) { Suma::Fixtures.order.create }

    it "sends the order confirmation" do
      order.checkout.cart.offering.update(confirmation_template: "2022-12-pilot-confirmation")
      expect do
        order.publish_immediate("created", order.id)
      end.to perform_async_job(Suma::Async::OrderConfirmation)

      expect(Suma::Message::Delivery.all).to contain_exactly(
        have_attributes(
          template: "offerings/2022-12-pilot-confirmation",
          transport_type: "sms",
          template_language: "en",
        ),
      )
    end

    it "noops if the offering has no template" do
      expect do
        order.publish_immediate("created", order.id)
      end.to perform_async_job(Suma::Async::OrderConfirmation)

      expect(Suma::Message::Delivery.all).to be_empty
    end
  end

  describe "PlaidUpdateInstitutions" do
    it "updates Plaid institutions" do
      Suma::Plaid.sync_institutions = true
      Suma::Plaid.bulk_sync_sleep = 0
      resp_json = load_fixture_data("plaid/institutions_get")
      headers = {"Content-Type" => "application/json"}
      req1 = stub_request(:post, "https://sandbox.plaid.com/institutions/get").
        with(body: hash_including("offset" => 0)).
        to_return(status: 200, body: resp_json.to_json, headers:)
      req2 = stub_request(:post, "https://sandbox.plaid.com/institutions/get").
        with(body: hash_including("offset" => 50)).
        to_return(status: 200, body: resp_json.merge("institutions" => []).to_json, headers:)

      Suma::Async::PlaidUpdateInstitutions.new.perform(true)

      expect(Suma::PlaidInstitution.all).to have_length(5)
      expect(req1).to have_been_made
      expect(req2).to have_been_made
    end

    it "noops if unconfigured" do
      Suma::Plaid.sync_institutions = false
      Suma::Async::PlaidUpdateInstitutions.new.perform(true)
      expect(Suma::PlaidInstitution.all).to be_empty
    end
  end

  describe "ResetCodeCreateDispatch" do
    it "sends an sms for an sms reset code" do
      member = Suma::Fixtures.member(phone: "12223334444").create
      expect do
        member.add_reset_code(token: "12345", transport: "sms")
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
