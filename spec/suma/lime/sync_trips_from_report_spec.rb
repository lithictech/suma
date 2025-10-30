# frozen_string_literal: true

require "suma/spec_helpers/sentry"

require "suma/lime/sync_trips_from_report"

RSpec.describe Suma::Lime::SyncTripsFromReport, :db, reset_configuration: Suma::Lime do
  include Suma::SpecHelpers::Sentry

  describe "run_for_report" do
    let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger.registered_as_stripe_customer.create }
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create(member:) }
    let(:mc) { Suma::Fixtures.anon_proxy_member_contact.email("m1@in.mysuma.org").create(member:) }
    let(:rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }
    let(:program) do
      Suma::Fixtures.program.with_pricing(
        vendor_service:,
        vendor_service_rate: rate,
      ).create
    end

    before(:each) do
      Suma::Lime.trip_report_vendor_configuration_id = va.configuration_id
      va.add_registration(external_program_id: mc.email)
      va.configuration.add_program(program)
    end

    it "creates trips from csv rows" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$1.00,$3.44,$19.06,m1@in.mysuma.org
        RTOKEN2,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$1.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to contain_exactly(
        have_attributes(
          vehicle_id: "RTOKEN1",
          vendor_service: be === program.pricings.first.vendor_service,
          begin_lat: 0.0,
          begin_lng: 0.0,
          began_at: match_time("2025-09-16T00:01:00-0700"),
          end_lat: 0.0,
          end_lng: 0.0,
          ended_at: match_time("2025-09-16T00:43:00-0700"),
          vendor_service_rate: be === program.pricings.first.vendor_service_rate,
          member: be === member,
          external_trip_id: "RTOKEN1",
          vehicle_type: "escooter",
          our_cost: cost("$1"),
        ),
        have_attributes(vehicle_id: "RTOKEN2"),
      )
      expect(Suma::Mobility::Trip[external_trip_id: "RTOKEN1"].charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0.00"), memo: have_attributes(en: "Unlock fee")),
        have_attributes(amount: cost("$0.00"), memo: have_attributes(en: "Riding - $0.00/min (42 min)")),
      )
    end

    it "only looks at the configured vendor configuration" do
      Suma::Lime.trip_report_vendor_configuration_id = 0
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to be_empty
    end

    it "calculates and charges the cost based on rate" do
      card = Suma::Fixtures.card.member(member).create
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$1,$3.44,$19.06,m1@in.mysuma.org
      CSV
      rate.update(surcharge_cents: 50, unit_amount_cents: 7)
      rate.update(undiscounted_rate: Suma::Fixtures.vendor_service_rate.unit_amount(35).surcharge(100).create)
      described_class.new.run_for_report(txt)
      charge = Suma::Mobility::Trip.first.charge
      expect(charge).to have_attributes(undiscounted_subtotal: cost("$15.70"))
      expect(charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Unlock fee", cost("$0.50")],
        ["Riding - $0.07/min (42 min)", cost("$2.94")],
      )
      expect(charge.associated_funding_transactions).to contain_exactly(
        have_attributes(amount: cost("$3.44")),
      )
      expect(charge.associated_funding_transactions.first.stripe_card_strategy).to have_attributes(
        originating_card: be === card,
      )
    end

    it "does not charge the user if the Lime ACTUAL_COST is $0" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0,$0,$19.06,m1@in.mysuma.org
      CSV
      rate.update(surcharge_cents: 50, unit_amount_cents: 7)
      rate.update(undiscounted_rate: Suma::Fixtures.vendor_service_rate.unit_amount(35).surcharge(100).create)
      described_class.new.run_for_report(txt)
      charge = Suma::Mobility::Trip.first.charge
      expect(charge).to have_attributes(undiscounted_subtotal: cost("$0"))
      expect(charge.line_items.map { |li| [li.memo.en, li.amount] }).to contain_exactly(
        ["Ride cancelled", cost("$0")],
      )
      expect(charge.associated_funding_transactions).to be_empty
      expect(charge.contributing_book_transactions).to be_empty
    end

    it "will use payment triggers for subsidy" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$1.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      Suma::Fixtures.card.member(member).create
      rate.update(surcharge_cents: 50, unit_amount_cents: 7)
      Suma::Fixtures.payment_trigger.
        from_platform_category(vendor_service.categories.first).
        matching(1).
        create(active_during: Time.parse("2025-09-01")..Time.parse("2025-09-30"))
      described_class.new.run_for_report(txt)
      trip = Suma::Mobility::Trip.find!(external_trip_id: "RTOKEN1")
      expect(trip.member.payment_account.originated_funding_transactions).to contain_exactly(
        have_attributes(amount: cost("$1.72")),
      )
    end

    it "parses the absurd time formats properly" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
        RTOKEN2,09/16/2025 01:01 AM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
        RTOKEN3,09/16/2025 12:01 PM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
        RTOKEN4,09/16/2025 13:01 PM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to contain_exactly(
        have_attributes(began_at: match_time("2025-09-16T00:01:00-0700")),
        have_attributes(began_at: match_time("2025-09-16T01:01:00-0700")),
        have_attributes(began_at: match_time("2025-09-16T12:01:00-0700")),
        have_attributes(began_at: match_time("2025-09-16T13:01:00-0700")),
      )
    end

    it "warns if no program registration with the email exists" do
      va.registrations.first.destroy
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      expect_sentry_capture(type: :message, arg_matcher: eq("Lime trip taken by unknown user"))
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to be_empty
    end

    it "errors if there is not only 1 program for the configuration, so we cannot figure out which one to use" do
      va.configuration.add_program(Suma::Fixtures.program.create)
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      expect do
        described_class.new.run_for_report(txt)
      end.to raise_error(/have exactly 1 item/)
    end

    it "errors if the associated program does not have pricing" do
      program.pricings.first.destroy
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      expect do
        described_class.new.run_for_report(txt)
      end.to raise_error(ArgumentError, /must have exactly 1 item/)
    end

    it "does not create duplicate trips" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to have_length(1)
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to have_length(1)
    end
  end

  describe "dataset" do
    before(:each) do
      Suma::Lime.trip_report_from_email = "from@mysuma.org"
      Suma::Lime.trip_report_to_email = "to@mysuma.org"
    end

    let(:now) { Time.now }

    it "finds only emails with the configured to and from address" do
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        to_email: "to@mysuma.org",
        from_email: "from@mysuma.org",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "flipped",
        to_email: "from@mysuma.org",
        from_email: "to@mysuma.org",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "old",
        to_email: "to@mysuma.org",
        from_email: "from@mysuma.org",
        timestamp: now - 4.weeks,
        data: "{}",
      )
      expect(described_class.new.dataset.select_map(&:message_id)).to contain_exactly("valid")
    end

    it "can use an ILIKE statement for the from email" do
      Suma::Lime.trip_report_from_email = "%@mysuma.org"
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "v1",
        to_email: "to@mysuma.org",
        from_email: "x1@mysuma.org",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "v2",
        to_email: "to@mysuma.org",
        from_email: "x2@mysuma.org",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "other",
        to_email: "to@mysuma.org",
        from_email: "x1@other.mysuma.org",
        timestamp: now,
        data: "{}",
      )
      expect(described_class.new.dataset.select_map(&:message_id)).to contain_exactly("v1", "v2")
    end
  end

  describe "run" do
    let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger.registered_as_stripe_customer.create }
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create(member:) }
    let(:mc) { Suma::Fixtures.anon_proxy_member_contact.email("m1@in.mysuma.org").create(member:) }
    let(:rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:program) do
      Suma::Fixtures.program.with_pricing(
        vendor_service: Suma::Fixtures.vendor_service.mobility_deeplink.create,
        vendor_service_rate: rate,
      ).create
    end

    before(:each) do
      described_class.new.row_iterator.reset
      va.add_registration(external_program_id: mc.email)
      va.configuration.add_program(program)
      Suma::Lime.trip_report_vendor_configuration_id = va.configuration_id
      Suma::Lime.trip_report_from_email = "from@mysuma.org"
      Suma::Lime.trip_report_to_email = "to@mysuma.org"
    end

    after(:each) do
      described_class.new.row_iterator.reset
    end

    def csv_attachment(text)
      return {
        Name: "Report.csv",
        Content: Base64.strict_encode64(text),
        ContentID: "f_mg5b72r40",
        ContentType: "text/csv",
        ContentLength: text.length,
      }
    end

    it "syncs all reports in the dataset" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org
      CSV

      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "from@mysuma.org",
        to_email: "to@mysuma.org",
        timestamp: Time.now,
        data: {Attachments: [csv_attachment(txt)]}.to_json,
      )

      described_class.new.run
      expect(Suma::Mobility::Trip.all).to contain_exactly(
        have_attributes(
          vehicle_id: "RTOKEN1",
        ),
      )
    end
  end
end
