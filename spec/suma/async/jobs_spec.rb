# frozen_string_literal: true

require "suma/async"
require "suma/frontapp"
require "suma/lime"
require "suma/lyft"
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

  describe "Emailer" do
    it "sends emails" do
      d = Suma::Fixtures.message_delivery.create
      Timecop.freeze do
        Suma::Async::Emailer.new.perform
        expect(d.refresh).to have_attributes(sent_at: match_time(:now))
      end
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

  describe "FrontappListSync", reset_configuration: Suma::Frontapp do
    before(:each) do
      Suma::Frontapp.auth_token = "faketoken"
      Suma::Frontapp.list_sync_enabled = true
    end

    it "syncs marketing lists" do
      get_req = stub_request(:get, "https://api2.frontapp.com/contact_groups").
        to_return(
          json_response({}),
          json_response({}),
        )
      Suma::Async::FrontappListSync.new.perform
      expect(get_req).to have_been_made.times(2)
    end

    it "noops if sync not enabled" do
      Suma::Frontapp.list_sync_enabled = false
      expect { Suma::Async::FrontappListSync.new.perform }.to_not raise_error
    end

    it "noops if client not configured" do
      Suma::Frontapp.auth_token = ""
      expect { Suma::Async::FrontappListSync.new.perform }.to_not raise_error
    end
  end

  describe "FrontappUpsertContact", reset_configuration: Suma::Frontapp do
    it "upserts front contacts" do
      Suma::Frontapp.auth_token = "fake token"
      req = stub_request(:post, "https://api2.frontapp.com/contacts").
        to_return(fixture_response("front/contact"))

      member = nil
      expect do
        member = Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::FrontappUpsertContact)

      expect(req).to have_been_made
    end

    it "noops if Front is not configured" do
      expect do
        Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::FrontappUpsertContact)
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

  describe "LyftPassTripSync", reset_configuration: Suma::Lyft do
    it "syncs trips" do
      Suma::Lyft.pass_authorization = "Basic xyz"
      Suma::Lyft.pass_email = "a@b.c"
      Suma::Lyft.pass_org_id = "1234"

      vendor_service_rate = Suma::Fixtures.vendor_service_rate.create
      vendor_service_rate.add_service(
        Suma::Fixtures.vendor_service.create(
          vendor: Suma::Lyft.mobility_vendor, mobility_vendor_adapter_key: "lyft_deeplink",
        ),
      )
      Suma::Lyft.pass_vendor_service_rate_id = vendor_service_rate.id
      Suma::Fixtures.program.create(lyft_pass_program_id: "5678")

      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: {cookies: {}}.to_json,
      )

      req = stub_request(:post, "https://www.lyft.com/v1/enterprise-insights/search/transactions?organization_id=1234&start_time=1546300800000").
        to_return(
          status: 200,
          headers: {
            "Content-Type" => "application/json",
          },
          body: {
            "aggs" => {},
            "next_token" => nil,
            "results" => [],
            "total_results" => 0,
          }.to_json,
        )

      Suma::Async::LyftPassTripSync.new.perform

      expect(req).to have_been_made
    end

    it "noops if not configured" do
      expect do
        Suma::Async::LyftPassTripSync.new.perform
      end.to_not raise_error
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
        Suma::Member::ResetCode.replace_active(member, token: "12345", transport: "sms")
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

  describe "ResetCodeUpdateTwilio" do
    let(:member) { Suma::Fixtures.member(phone: "12223334444").create }
    let(:fac) { Suma::Fixtures.reset_code(member:).sms }

    it "noops if the code has no delivery, has an invalid message id or the delivery was aborted" do
      no_delivery = fac.create
      bad_msg_id = fac.create
      bad_msg_id.update(message_delivery: Suma::Fixtures.message_delivery.create(transport_message_id: "MSGID"))
      template = Suma::Message::SmsTransport.verification_template
      message_delivery = Suma::Fixtures.message_delivery.via("sms").create(template:, transport_message_id: nil)
      nil_msg_id = fac.create(message_delivery:)
      expect do
        no_delivery.expire!
        bad_msg_id.expire!
        nil_msg_id.expire!
      end.to perform_async_job(Suma::Async::ResetCodeUpdateTwilio)
    end

    it "noops if the reset code message delivery does not use the verification template" do
      message_delivery = Suma::Fixtures.message_delivery.sent_to_verification.create
      message_delivery.update(template: "alt-verification")
      code = fac.create(message_delivery:)

      expect do
        code.use!
      end.to perform_async_job(Suma::Async::ResetCodeUpdateTwilio)
    end

    it "tells twilio about used and canceled codes" do
      req123 = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications/VE123").
        with(body: {"Status" => "canceled"}).
        to_return(status: 200, body: "{}")
      req456 = stub_request(:post, "https://verify.twilio.com/v2/Services/VA555test/Verifications/VE456").
        with(body: {"Status" => "approved"}).
        to_return(status: 200, body: "{}")

      pending = fac.create
      pending.update(message_delivery: Suma::Fixtures.message_delivery.sent_to_verification("VE123").create)
      using = fac.create
      using.update(message_delivery: Suma::Fixtures.message_delivery.sent_to_verification("VE456").create)

      expect do
        Suma::Member::ResetCode.use_code_with_token(using.token) { nil }
      end.to perform_async_job(Suma::Async::ResetCodeUpdateTwilio)

      expect(req123).to have_been_made
      expect(req456).to have_been_made
    end
  end

  describe "SignalwireProcessOptouts", reset_configuration: Suma::Signalwire do
    it "syncs refunds" do
      Suma::Signalwire.marketing_number = "12225550000"
      member = Suma::Fixtures.member.create
      Suma::Webhookdb.signalwire_messages_dataset.insert(
        signalwire_id: "msg1",
        date_created: 4.days.ago,
        direction: "inbound",
        from: "+" + member.phone,
        to: "+12225550000",
        data: {body: "stop"}.to_json,
      )
      expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: false)
      Suma::Async::SignalwireProcessOptouts.new.perform
      expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: true)
    end

    it "noops if signalwire marketing number not configured" do
      member = Suma::Fixtures.member.create
      Suma::Webhookdb.signalwire_messages_dataset.insert(
        signalwire_id: "msg1",
        date_created: 4.days.ago,
        direction: "inbound",
        from: "+" + member.phone,
        to: "+12225550000",
        data: {body: "stop"}.to_json,
      )
      Suma::Async::SignalwireProcessOptouts.new.perform
      expect(member.refresh.preferences!).to have_attributes(marketing_sms_optout: false)
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

  describe "SyncLyftFreeBikeStatusGbfs", reset_configuration: Suma::Lyft do
    before(:each) do
      Suma::Fixtures.vendor_service(vendor: Suma::Lyft.mobility_vendor).mobility.create
    end

    it "sync lyft scooters gbfs" do
      Suma::Lyft.sync_enabled = true
      reqs = ["free_bike_status", "vehicle_types", "station_information", "station_status"].map do |s|
        stub_request(:get, "https://gbfs.lyft.com/gbfs/2.3/pdx/en/#{s}.json").
          to_return(fixture_response("lyft/#{s}"))
      end

      Suma::Async::SyncLyftFreeBikeStatusGbfs.new.perform(true)
      expect(reqs).to all(have_been_made)
    end

    it "noops if Lyft is not configured" do
      expect do
        Suma::Async::SyncLyftFreeBikeStatusGbfs.new.perform(true)
      end.to_not raise_error
    end
  end

  describe "FrontappUpsertContact", reset_configuration: Suma::Frontapp do
    before(:each) do
      Suma::Frontapp.auth_token = "fake token"
    end
    it "upserts front contacts" do
      req = stub_request(:post, "https://api2.frontapp.com/contacts").
        to_return(fixture_response("front/contact"))

      expect do
        Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::FrontappUpsertContact)

      expect(req).to have_been_made
    end

    it "noops if Front is not configured" do
      Suma::Frontapp.auth_token = ""
      expect do
        Suma::Fixtures.member.create
      end.to perform_async_job(Suma::Async::FrontappUpsertContact)
    end

    it "noops if the update does not change meaningful fields" do
      m = Suma::Fixtures.member.create
      m.updated_at = 3.minutes.from_now
      expect do
        m.save_changes
      end.to perform_async_job(Suma::Async::FrontappUpsertContact)
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

    it "reschedules for the future if the advisory lock is taken" do
      expect(Suma::Async::ProcessAnonProxyInboundWebhookdbRelays).to receive(:perform_in)
      j = Suma::Async::ProcessAnonProxyInboundWebhookdbRelays.new
      Sequel.connect(Suma::Postgres::Model.uri) do |db|
        j.advisory_lock(db:).with_lock do
          j.perform(true)
        end
      end
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
