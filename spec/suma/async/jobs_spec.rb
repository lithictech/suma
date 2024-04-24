# frozen_string_literal: true

require "suma/async"
require "suma/frontapp"
require "suma/lime"
require "suma/messages/specs"
require "rspec/eventually"

RSpec.describe "suma async jobs", :async, :db, :do_not_defer_events, :no_transaction_check do
  before(:all) do
    Suma::Async.setup_tests
  end

  describe "AnalyticsDispatch" do
    it "upserts analytics rows for transactional model updates" do
      expect do
        Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::AnalyticsDispatch)

      expect(Suma::Analytics::Member.all).to have_length(1)
    end

    it "destroys analytics rows for transactional model updates" do
      member = Suma::Fixtures.member.create
      Suma::Analytics.upsert_from_transactional_model(member)
      expect(Suma::Analytics::Member.dataset.all).to have_length(1)
      expect do
        member.destroy
      end.to perform_async_job(Suma::Async::AnalyticsDispatch)

      expect(Suma::Analytics::Member.all).to be_empty
    end

    it "noops for non-lifecycle events" do
      m = Suma::Fixtures.member.create
      expect do
        m.publish_immediate("foo", m.id)
      end.to perform_async_job(Suma::Async::AnalyticsDispatch)

      expect(Suma::Analytics::Member.all).to be_empty
    end

    it "raises if no model class is found for the lifecycle event" do
      event = Amigo::Event.new("abc", "suma.nomodel.created", [1]).as_json
      expect do
        Suma::Async::AnalyticsDispatch.new.perform(event)
      end.to raise_error(/cannot find model for suma\.nomodel/)
    end

    it "noops for transactional models which do not have analytics handlers" do
      expect do
        Suma::Fixtures.uploaded_file.create
      end.to perform_async_job(Suma::Async::AnalyticsDispatch)

      expect(Suma::Analytics::Member.all).to be_empty
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
    it "dispatches the code" do
      member = Suma::Fixtures.member(phone: "12223334444").create
      expect do
        member.add_reset_code(token: "12345", transport: "sms")
      end.to perform_async_job(Suma::Async::ResetCodeCreateDispatch)

      expect(Suma::Message::Delivery.all).to contain_exactly(
        have_attributes(
          template: "verification",
          transport_type: "sms",
          to: "12223334444",
        ),
      )
    end
  end

  describe "StripeRefundsBackfiller" do
    it "syncs refunds" do
      Suma::Webhookdb.stripe_refunds_dataset.insert(
        stripe_id: "re_abc",
        amount: 250,
        charge: "ch_abc",
        created: Time.now,
        status: "succeeded",
        data: {id: "re_abc", status: "succeeded"}.to_json,
      )
      funding_strategy = Suma::Payment::FundingTransaction::StripeCardStrategy.create(
        originating_card: Suma::Fixtures.card.create,
        charge_json: {id: "ch_abc"}.to_json,
      )
      Suma::Fixtures.funding_transaction(strategy: funding_strategy).create
      Suma::Async::StripeRefundsBackfiller.new.perform
      expect(Suma::Payment::PayoutTransaction::StripeChargeRefundStrategy.all).to contain_exactly(
        have_attributes(stripe_charge_id: "ch_abc"),
      )
    end
  end

  describe "SyncLimeFreeBikeStatusGbfs", reset_configuration: Suma::Lime do
    before(:each) do
      Suma::Fixtures.vendor_service(vendor: Suma::Lime.mobility_vendor).mobility.create
    end

    it "sync lime scooters gbfs" do
      Suma::Lime.auth_token = "fake token"
      free_bike_status_req = stub_request(:get, "https://data.lime.bike/api/partners/v2/gbfs_transit/free_bike_status.json").
        to_return(fixture_response("lime/free_bike_status"))
      vehicle_types_req = stub_request(:get, "https://data.lime.bike/api/partners/v2/gbfs_transit/vehicle_types.json").
        to_return(fixture_response("lime/vehicle_types"))

      Suma::Async::SyncLimeFreeBikeStatusGbfs.new.perform(true)
      expect(free_bike_status_req).to have_been_made
      expect(vehicle_types_req).to have_been_made
      expect(Suma::Mobility::Vehicle.all).to have_length(1)
    end

    it "noops if Lime is not configured" do
      expect do
        Suma::Async::SyncLimeFreeBikeStatusGbfs.new.perform(true)
      end.to_not raise_error
    end
  end

  describe "SyncLimeGeofencingZonesGbfs", reset_configuration: Suma::Lime do
    before(:each) do
      Suma::Fixtures.vendor_service(vendor: Suma::Lime.mobility_vendor).mobility.create
    end

    it "sync geofencing zones gbfs" do
      Suma::Lime.auth_token = "fake token"
      geofencing_zone_req = stub_request(:get, "https://data.lime.bike/api/partners/v2/gbfs_transit/geofencing_zones.json").
        to_return(fixture_response("lime/geofencing_zone"))
      vehicle_types_req = stub_request(:get, "https://data.lime.bike/api/partners/v2/gbfs_transit/vehicle_types.json").
        to_return(fixture_response("lime/vehicle_types"))

      Suma::Async::SyncLimeGeofencingZonesGbfs.new.perform(true)
      expect(geofencing_zone_req).to have_been_made
      expect(vehicle_types_req).to have_been_made
      expect(Suma::Mobility::RestrictedArea.all).to have_length(1)
    end

    it "noops if Lime is not configured" do
      expect do
        Suma::Async::SyncLimeGeofencingZonesGbfs.new.perform(true)
      end.to_not raise_error
    end
  end

  describe "UpsertFrontappContact", reset_configuration: Suma::Frontapp do
    it "upserts front contacts" do
      Suma::Frontapp.auth_token = "fake token"
      req = stub_request(:post, "https://api2.frontapp.com/contacts").
        to_return(fixture_response("front/contact"))

      member = nil
      expect do
        member = Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::UpsertFrontappContact)

      expect(req).to have_been_made
      expect(member.refresh).to have_attributes(frontapp_contact_id: "crd_123")
    end

    it "noops if Front is not configured" do
      expect do
        Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::UpsertFrontappContact)
    end
  end

  describe "OfferingScheduleFulfillment" do
    it "on create, enqueues a processing job at the fulfillment time" do
      o = Suma::Fixtures.offering.timed_fulfillment.create
      expect(Suma::Async::OfferingBeginFulfillment).to receive(:perform_at).
        with(match_time(o.begin_fulfillment_at).within(1), o.id)
      expect do
        o.publish_immediate("created", o.id)
      end.to perform_async_job(Suma::Async::OfferingScheduleFulfillment)
    end

    it "on update, enqueues a processing job at the fulfillment time" do
      o = Suma::Fixtures.offering.timed_fulfillment.create
      t2 = 2.hours.from_now
      expect(Suma::Async::OfferingBeginFulfillment).to receive(:perform_at).
        with(match_time(t2).within(1), o.id)
      expect do
        o.update(begin_fulfillment_at: t2)
      end.to perform_async_job(Suma::Async::OfferingScheduleFulfillment)
    end

    it "noops if there is no fulfillment time" do
      o = Suma::Fixtures.offering.create
      expect(Suma::Async::OfferingBeginFulfillment).to_not receive(:perform_at)
      expect do
        o.publish_immediate("created", o.id)
      end.to perform_async_job(Suma::Async::OfferingScheduleFulfillment)
    end
  end

  describe "OfferingBeginFulfillment" do
    it "begins fulfillment" do
      o = Suma::Fixtures.offering.timed_fulfillment(1.hour.ago).create
      order = Suma::Fixtures.order.create
      order.checkout.cart.update(offering: o)
      # The OfferingBeginFulfillment job will be called by the OfferingScheduleFulfillment job
      expect(Suma::Async::OfferingBeginFulfillment).to receive(:perform_at).and_call_original
      expect do
        o.publish_immediate("created", o.id)
      end.to perform_async_job(Suma::Async::OfferingScheduleFulfillment)
      expect(order.refresh).to have_attributes(fulfillment_status: "fulfilling")
    end
  end

  describe "ProcessAnonProxyInboundRelays" do
    before(:each) do
      Suma::AnonProxy::MessageHandler::Fake.reset
      Suma::AnonProxy::MessageHandler::Fake.can_handle_callback = proc { true }
      Suma::Webhookdb.postmark_inbound_messages_dataset.delete
      relay = Suma::AnonProxy::Relay.create!("postmark")
      Suma::Redis.cache.with do |c|
        c.call("DEL", Suma::Async::ProcessAnonProxyInboundWebhookdbRelays.relay_cache_key(relay))
      end
    end

    it "processes webhookdb rows with Postmark" do
      va = Suma::Fixtures.anon_proxy_vendor_account.with_contact(relay_key: "postmark").create

      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        to_email: va.contact.email,
        from_email: "fake-handler",
        data: Sequel.pg_jsonb({"HtmlBody" => "body"}),
        timestamp: Time.now,
        message_id: "msgid",
      )
      Suma::Async::ProcessAnonProxyInboundWebhookdbRelays.new.perform(true)
      expect(Suma::AnonProxy::MessageHandler::Fake.handled).to contain_exactly(
        have_attributes(message_id: "msgid"),
      )

      # Ensure we keep track of what's been synced
      Suma::Async::ProcessAnonProxyInboundWebhookdbRelays.new.perform(true)
      expect(Suma::AnonProxy::MessageHandler::Fake.handled).to have_length(1)
    end
  end

  describe "MemberOnboardingVerifiedDispatch" do
    let(:member) { Suma::Fixtures.member.create }

    it "dispatches an SMS to the member preferred messaging" do
      expect do
        member.update(onboarding_verified_at: Time.now)
      end.to perform_async_job(Suma::Async::MemberOnboardingVerifiedDispatch)

      expect(Suma::Message::Delivery.all).to contain_exactly(
        have_attributes(template: "onboarding_verification"),
      )
    end

    it "noops if member is not currently verified" do
      expect do
        member.publish_immediate("updated", member.pk, {onboarding_verified_at: [nil, Time.now.iso8601]})
      end.to perform_async_job(Suma::Async::MemberOnboardingVerifiedDispatch)

      expect(Suma::Message::Delivery.all).to be_empty
    end

    it "noops if the verification is older than the past week" do
      expect do
        member.update(onboarding_verified_at: 8.days.ago)
      end.to perform_async_job(Suma::Async::MemberOnboardingVerifiedDispatch)

      expect(Suma::Message::Delivery.all).to be_empty
    end
  end
end
