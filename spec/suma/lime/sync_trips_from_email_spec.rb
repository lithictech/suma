# frozen_string_literal: true

require "suma/lime/sync_trips_from_email"

RSpec.describe Suma::Lime::SyncTripsFromEmail, :db do
  before(:each) do
    Suma::Webhookdb.postmark_inbound_messages_dataset.delete
    described_class.new.row_iterator.reset
  end

  describe "run" do
    let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger.create }
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create(member:) }
    let(:mc) { Suma::Fixtures.anon_proxy_member_contact.email.create(member:) }
    let(:program) do
      Suma::Fixtures.program.with_pricing(
        vendor_service: Suma::Fixtures.vendor_service.
          mobility.
          create(mobility_vendor_adapter_key: "lime_deeplink"),
        vendor_service_rate: Suma::Fixtures.vendor_service_rate.create,
      ).create
    end
    let(:text_body) do
      <<~TXT
        Start Fee
        $0.50
        Riding - $0.07/min (76 min)
        $5.32
        Discount
        -$5.82
        Subtotal
        $0.00
        Total
        FREE
      TXT
    end

    before(:each) do
      va.add_registration(external_program_id: mc.email)
      va.configuration.add_program(program)
    end

    it "creates trips from receipt emails" do
      now = Time.parse("2024-07-15T12:00:00Z")
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: mc.email,
        subject: "Receipt for your Lime ride",
        timestamp: now,
        data: Sequel.pg_jsonb({"TextBody" => text_body}),
      )
      Timecop.freeze(now) do
        described_class.new.run
      end

      expect(Suma::Mobility::Trip.all).to contain_exactly(
        have_attributes(
          vehicle_id: "valid",
          vendor_service: be === program.pricings.first.vendor_service,
          begin_lat: 0.0,
          begin_lng: 0.0,
          began_at: match_time("2024-07-15T10:43:00Z"),
          end_lat: 0.0,
          end_lng: 0.0,
          ended_at: match_time("2024-07-15T11:59:00Z"),
          vendor_service_rate: be === program.pricings.first.vendor_service_rate,
          member: be === member,
          external_trip_id: "valid",
          vehicle_type: "escooter",
        ),
      )
      expect(Suma::Mobility::Trip.first.charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0.50"), memo: have_attributes(en: "Start Fee")),
        have_attributes(amount: cost("$5.32"), memo: have_attributes(en: "Riding - $0.07/min (76 min)")),
        have_attributes(amount: cost("-$5.82"), memo: have_attributes(en: "Discount")),
      )
    end

    it "noops if no program registration with the email exists" do
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: "m1@in.mysuma.org",
        subject: "Receipt for your Lime ride",
        timestamp: Time.now,
        data: "{}",
      )
      described_class.new.run

      expect(Suma::Mobility::Trip.all).to be_empty
    end

    it "errors if there is not only 1 program for the configuration, so we cannot figure out which one to use" do
      va.configuration.add_program(Suma::Fixtures.program.create)

      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: mc.email,
        subject: "Receipt for your Lime ride",
        timestamp: Time.now,
        data: "{}",
      )
      expect do
        described_class.new.run
      end.to raise_error(/have exactly 1 item/)
    end

    it "errors if the associated program does not have pricing" do
      program.pricings.first.destroy

      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: mc.email,
        subject: "Receipt for your Lime ride",
        timestamp: Time.now,
        data: Sequel.pg_jsonb({"TextBody" => text_body}),
      )

      expect do
        described_class.new.run
      end.to raise_error(ArgumentError, /must have exactly 1 item/)
    end

    it "does not create duplicate trips" do
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: mc.email,
        subject: "Receipt for your Lime ride",
        timestamp: Time.now,
        data: Sequel.pg_jsonb({"TextBody" => text_body}),
      )
      described_class.new.run
      described_class.new.row_iterator.reset
      described_class.new.run
      expect(Suma::Mobility::Trip).to receive(:where).and_return([])
      described_class.new.run
      expect(Suma::Mobility::Trip.all).to have_length(1)
    end

    it "handles paused charges" do
      text = <<~TXT
        Start Fee
        $0.50
        Riding - $0.07/min (18 min)
        $2.31
        Pause - $0.07/min (15 min)
        $1.05
        Discount
        -$2.81
        Subtotal
        $0.00
        Total
        FREE
      TXT
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: mc.email,
        subject: "Receipt for your Lime ride",
        timestamp: Time.now,
        data: Sequel.pg_jsonb({"TextBody" => text}),
      )
      described_class.new.run
      expect(Suma::Mobility::Trip.all).to have_length(1)
      expect(Suma::Mobility::Trip.first.charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0.50"), memo: have_attributes(en: "Start Fee")),
        have_attributes(amount: cost("$1.26"), memo: have_attributes(en: "Riding - $0.07/min (18 min)")),
        have_attributes(amount: cost("$1.05"), memo: have_attributes(en: "Pause - $0.07/min (15 min)")),
        have_attributes(amount: cost("-$2.81"), memo: have_attributes(en: "Discount")),
      )
    end

    it "errors if the assumptions about pause and riding are violated" do
      text = <<~TXT
        Start Fee
        $0.50
        Riding - $0.07/min (18 min)
        $1.26
        Pause - $0.07/min (15 min)
        $1.05
        Discount
        -$2.81
        Subtotal
        $0.00
        Total
        FREE
      TXT
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        to_email: mc.email,
        subject: "Receipt for your Lime ride",
        timestamp: Time.now,
        data: Sequel.pg_jsonb({"TextBody" => text}),
      )
      expect do
        described_class.new.run
      end.to raise_error(/unexpected pause and riding line items/)
    end
  end

  describe "dataset" do
    it "ignores messages that are not receipts or are old" do
      now = Time.now
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "valid",
        from_email: "no-reply@li.me",
        subject: "Receipt for your Lime ride",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "bad-subject",
        from_email: "no-reply@li.me",
        subject: "Something else",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "bad-from",
        from_email: "support@lime.com",
        subject: "Receipt for your Lime ride",
        timestamp: now,
        data: "{}",
      )
      Suma::Webhookdb.postmark_inbound_messages_dataset.insert(
        message_id: "old",
        from_email: "no-reply@li.me",
        subject: "Receipt for your Lime ride",
        timestamp: now - 4.weeks,
        data: "{}",
      )
      expect(described_class.new.dataset.select_map(&:message_id)).to contain_exactly("valid")
    end
  end

  describe "parse_row_to_receipt" do
    it "parses the row" do
      txt = <<~TXT
        Thank you for riding with Lime.

        Summary
        Date of Issue: Aug 23, 2025


        Start Fee
        $0.50


        Riding - $0.07/min (76 min)
        $5.32


        Discount
        -$5.82


        Subtotal
        $0.00


        Total

        FREE
      TXT
      row = {message_id: "xyz", timestamp: Time.parse("2024-07-15T12:00:00Z"), data: {"TextBody" => txt}}
      receipt = described_class.new.parse_row_to_receipt(row)
      expect(receipt).to have_attributes(
        ride_id: "xyz",
        started_at: Time.parse("2024-07-15T10:43:00Z"),
        ended_at: Time.parse("2024-07-15T11:59:00Z"),
        total: cost("$0"),
        discount: cost("$5.82"),
        line_items: [
          include(amount: cost("$0.50"), memo: "Start Fee"),
          include(amount: cost("$5.32"), memo: "Riding - $0.07/min (76 min)"),
          include(amount: cost("-$5.82"), memo: "Discount"),
        ],
      )
    end

    it "can parse non-free rides" do
      txt = <<~TXT
        Thank you for riding with Lime.

        Summary
        Date of Issue: Aug 23, 2025


        Start Fee
        $0.50


        Riding - $0.07/min (76 min)
        $5.32


        Discount
        -$4.62


        Subtotal
        $1.20


        Total

        $1.20
      TXT
      row = {message_id: "xyz", timestamp: Time.parse("2024-07-15T12:00:00Z"), data: {"TextBody" => txt}}
      receipt = described_class.new.parse_row_to_receipt(row)
      expect(receipt).to have_attributes(
        total: cost("$1.20"),
      )
    end
  end
end
