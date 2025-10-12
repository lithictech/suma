# frozen_string_literal: true

require "suma/lime/sync_trips_from_report"

RSpec.describe Suma::Lime::SyncTripsFromReport, :db, reset_configuration: Suma::Lime do
  describe "run_for_report" do
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
      Suma::Lime.trip_report_vendor_configuration_id = va.configuration_id
      va.add_registration(external_program_id: mc.email)
      va.configuration.add_program(program)
    end

    it "creates trips from csv rows" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
        RTOKEN2,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
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
        ),
        have_attributes(vehicle_id: "RTOKEN2"),
      )
      expect(Suma::Mobility::Trip[external_trip_id: "RTOKEN1"].charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0.00"), memo: have_attributes(en: "Start Fee")),
        have_attributes(amount: cost("$0.00"), memo: have_attributes(en: "Riding - $0.00/min (42 min)")),
      )
    end

    it "only looks at the configured vendor configuration" do
      Suma::Lime.trip_report_vendor_configuration_id = 0
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to be_empty
    end

    it "calculates and charges the cost based on rate" do
      card = Suma::Fixtures.card.member(member).create
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$2.99,$3.44,$19.06,m1@in.mysuma.org,$0.77
      CSV
      rate.update(surcharge_cents: 5, unit_amount_cents: 7)
      described_class.new.run_for_report(txt)
      charge = Suma::Mobility::Trip.first.charge
      expect(charge).to have_attributes(undiscounted_subtotal: cost("$2.99"), discounted_subtotal: cost("$2.99"))
      expect(charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0.05"), memo: have_attributes(en: "Start Fee")),
        have_attributes(amount: cost("$2.94"), memo: have_attributes(en: "Riding - $0.07/min (42 min)")),
      )
      expect(charge.associated_funding_transactions.first.stripe_card_strategy).to have_attributes(
        originating_card: be === card,
      )
    end

    it "calculates discount based on undiscounted rate" do
      Suma::Fixtures.card.member(member).create
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.44,$3.44,$19.06,m1@in.mysuma.org,$0.77
      CSV
      rate.update(surcharge_cents: 2, unit_amount_cents: 1)
      rate.update(undiscounted_rate: Suma::Fixtures.vendor_service_rate.unit_amount(7).surcharge(5).create)
      described_class.new.run_for_report(txt)
      charge = Suma::Mobility::Trip.first.charge
      expect(charge).to have_attributes(undiscounted_subtotal: cost("$2.99"), discounted_subtotal: cost("$0.44"))
      expect(charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0.02"), memo: have_attributes(en: "Start Fee")),
        have_attributes(amount: cost("$0.42"), memo: have_attributes(en: "Riding - $0.01/min (42 min)")),
      )
    end

    it "parses the absurd time formats properly" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
        RTOKEN2,09/16/2025 01:01 AM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
        RTOKEN3,09/16/2025 12:01 PM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
        RTOKEN4,09/16/2025 13:01 PM,09/16/2025 23:59 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to contain_exactly(
        have_attributes(began_at: match_time("2025-09-16T00:01:00-0700")),
        have_attributes(began_at: match_time("2025-09-16T01:01:00-0700")),
        have_attributes(began_at: match_time("2025-09-16T12:01:00-0700")),
        have_attributes(began_at: match_time("2025-09-16T13:01:00-0700")),
      )
    end

    it "noops if no program registration with the email exists" do
      va.registrations.first.destroy
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
      CSV
      described_class.new.run_for_report(txt)
      expect(Suma::Mobility::Trip.all).to be_empty
    end

    it "errors if there is not only 1 program for the configuration, so we cannot figure out which one to use" do
      va.configuration.add_program(Suma::Fixtures.program.create)
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
      CSV
      expect do
        described_class.new.run_for_report(txt)
      end.to raise_error(/have exactly 1 item/)
    end

    it "errors if the associated program does not have pricing" do
      program.pricings.first.destroy
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
      CSV
      expect do
        described_class.new.run_for_report(txt)
      end.to raise_error(ArgumentError, /must have exactly 1 item/)
    end

    it "does not create duplicate trips" do
      txt = <<~CSV
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
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

    it "finds only emails with the configured to and from address" do
      now = Time.now
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
      va.add_registration(external_program_id: mc.email)
      va.configuration.add_program(program)
      Suma::Lime.trip_report_vendor_configuration_id = va.configuration_id
      Suma::Lime.trip_report_from_email = "from@mysuma.org"
      Suma::Lime.trip_report_to_email = "to@mysuma.org"
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
        TRIP_TOKEN,START_TIME,END_TIME,REGION_NAME,USER_TOKEN,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,ACTUAL_COST,INTERNAL_COST,NORMAL_COST,USER_EMAIL,Price per minute
        RTOKEN1,09/16/2025 12:01 AM,09/16/2025 12:43 AM,Portland,UTOKEN1,43,1.53,$0.00,$3.44,$19.06,m1@in.mysuma.org,$0.07
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
