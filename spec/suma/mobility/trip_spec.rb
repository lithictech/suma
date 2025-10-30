# frozen_string_literal: true

require "suma/behaviors"

RSpec.describe "Suma::Mobility::Trip", :db do
  let(:described_class) { Suma::Mobility::Trip }
  let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$15")).create }
  let(:rate) { Suma::Fixtures.vendor_service_rate.create }
  let(:t) { trunc_time(Time.now) }

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_trip.create).to be_a(described_class)
    expect(Suma::Fixtures.mobility_trip.charged.create).to have_attributes(charge: be_a(Suma::Charge))
  end

  it_behaves_like "a type with a single image" do
    let(:instance) { Suma::Fixtures.mobility_trip.create }
  end

  describe "start_trip" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_maas.create(external_name: "Super Scoot") }

    it "creates a trip with the given parameters" do
      trip = described_class.start_trip(
        member:,
        vehicle_id: "abcd",
        vehicle_type: "ebike",
        vendor_service:,
        rate:,
        lat: 1.5,
        lng: 2.5,
        now: t,
      )
      expect(trip).to have_attributes(
        member:,
        vehicle_id: "abcd",
        vehicle_type: "ebike",
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: 1.5,
        begin_lng: 2.5,
        began_at: t,
      )
    end

    it "errors if the member already has an ongoing trip" do
      ongoing = Suma::Fixtures.mobility_trip(member:).ongoing.create
      expect do
        described_class.start_trip(
          member:,
          vehicle_id: "abcd",
          vehicle_type: "ebike",
          vendor_service:,
          rate:,
          lat: 1.5,
          lng: 2.5,
          now: t,
        )
      end.to raise_error(described_class::OngoingTrip)
    end

    it "propogates other unique constraint violation errors" do
      Suma::Fixtures.mobility_trip(member:).ended.create(opaque_id: "abc")
      expect(Suma::Secureid).to receive(:new_opaque_id).and_return("abc")
      expect do
        described_class.start_trip(
          member:,
          vehicle_id: "abcd",
          vehicle_type: "ebike",
          vendor_service:,
          rate:,
          lat: 1.5,
          lng: 2.5,
          now: t,
        )
      end.to raise_error(Sequel::UniqueConstraintViolation)
    end

    it "errors if service usage is prohibited" do
      member.update(onboarding_verified: false)
      expect do
        described_class.start_trip(
          member:,
          vehicle_id: "abcd",
          vehicle_type: "ebike",
          vendor_service:,
          rate:,
          lat: 1.5,
          lng: 2.5,
          now: t,
        )
      end.to raise_error(Suma::Member::ReadOnlyMode)
    end
  end

  describe "start_trip_from_vehicle" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_maas.create }

    it "uses vehicle params for the trip" do
      v = Suma::Fixtures.mobility_vehicle.create(vendor_service:)
      trip = described_class.start_trip_from_vehicle(member:, vehicle: v, rate:)
      expect(trip).to have_attributes(
        vehicle_id: v.vehicle_id,
        vendor_service: be === v.vendor_service,
        begin_lat: v.lat,
        begin_lng: v.lng,
      )
    end

    it "errors if the service prohibits usage" do
      member.update(onboarding_verified: false)
      v = Suma::Fixtures.mobility_vehicle.create(vendor_service:)
      expect do
        described_class.start_trip_from_vehicle(member:, vehicle: v, rate:)
      end.to raise_error(Suma::Member::ReadOnlyMode)
    end
  end

  describe "end_trip" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_maas.create(external_name: "Super Scoot") }
    let!(:mobility_ledger) { Suma::Fixtures.ledger.member(member).category(:mobility).create }
    let!(:cash) { Suma::Fixtures.vendor_service_category.cash.create }
    let!(:mobility) { Suma::Fixtures.vendor_service_category.mobility.create }

    it "ends the trip and creates a charge using the returned cost" do
      trip = Suma::Fixtures.mobility_trip.ongoing.create(member:, vendor_service:)
      trip.end_trip(lat: 1, lng: 2, now: Time.now)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$0"),
        discounted_subtotal: cost("$0"),
        contributing_book_transactions: [],
      )
      expect(trip.charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$0"), memo: have_attributes(en: "Unlock fee")),
        have_attributes(amount: cost("$0"), memo: have_attributes(en: "Ride cost (0.00/min for 1 min)")),
      )
    end

    it "charges the service's category ledgers if there is a balance" do
      rate = Suma::Fixtures.vendor_service_rate.surcharge(200).unit_amount(20).discounted_by(0.5).create
      member_mobility_ledger = member.payment_account.ensure_ledger_with_category(mobility)
      Suma::Fixtures.book_transaction.to(member_mobility_ledger).create(amount: money("$1"))
      trip = Suma::Fixtures.mobility_trip(vendor_service:).
        ongoing.
        create(began_at: t - 211.seconds, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2, now: t)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        discounted_subtotal: cost("$2.80"),
        undiscounted_subtotal: cost("$5.60"),
      )
      expect(trip.charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$2"), memo: have_attributes(en: "Unlock fee")),
        have_attributes(amount: cost("$0.80"), memo: have_attributes(en: "Ride cost (0.20/min for 4 min)")),
      )
      expect(trip.charge.contributing_book_transactions).to contain_exactly(
        have_attributes(
          originating_ledger: member_mobility_ledger,
          receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(mobility),
          amount: cost("$1.00"),
          memo: have_attributes(en: start_with("Super Scoot - trp_")),
          associated_vendor_service_category: be === mobility,
        ),
        have_attributes(
          originating_ledger: member.payment_account.cash_ledger!,
          receiving_ledger: Suma::Payment::Account.lookup_platform_account.cash_ledger!,
          amount: cost("$1.80"),
          memo: have_attributes(en: start_with("Super Scoot - trp_")),
          associated_vendor_service_category: be === cash,
        ),
      )
    end

    describe "when there is a remaining cost to charge the member" do
      let(:rate) { Suma::Fixtures.vendor_service_rate.unit_amount(0).surcharge(200_00).create }
      let(:trip) do
        Suma::Fixtures.mobility_trip(vendor_service:).
          ongoing.
          create(began_at: t - 211.seconds, vendor_service_rate: rate, member:)
      end

      it "creates a funding transaction against the default payment instrument" do
        Suma::Fixtures::Members.register_as_stripe_customer(member)
        Suma::Fixtures.card.member(member).create

        trip.end_trip(lat: 1, lng: 2, now: t)
        expect(trip.charge.associated_funding_transactions).to contain_exactly(
          have_attributes(status: "created", amount: cost("$185")),
        )
        expect(trip.charge.contributing_book_transactions).to contain_exactly(
          have_attributes(
            originating_ledger: member.payment_account.cash_ledger!,
            receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(cash),
            amount: cost("$200"),
            memo: have_attributes(en: start_with("Super Scoot - trp_")),
            associated_vendor_service_category: be === cash,
          ),
        )
      end

      it "creates a support ticket if money is required and there is no payment instrument" do
        trip.end_trip(lat: 1, lng: 2, now: Time.now)
        expect(trip.charge).to be_a(Suma::Charge)
        expect(Suma::Support::Ticket.all).to contain_exactly(
          have_attributes(body: /could not be charged/),
        )
      end
    end

    it "does not create any book transactions for a $0 trip cost" do
      Suma::Payment.ensure_cash_ledger(member)
      member.refresh
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(0).surcharge(0).create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service:, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2, now: Time.now)
      expect(trip.charge).to have_attributes(discounted_subtotal: cost("$0"))
      expect(trip.charge.contributing_book_transactions).to be_empty
      expect(trip.charge.associated_funding_transactions).to be_empty
      expect(trip.charge.line_items).to have_length(2)
    end
  end

  describe "charge_trip" do
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }
    let(:began_at) { 30.minutes.ago }

    it "charges the trip" do
      trip = described_class.new(
        member:,
        vehicle_id: "abcd",
        vehicle_type: "ebike",
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: 1.5,
        begin_lng: 2.5,
        began_at:,
        end_lat: 3,
        end_lng: 4,
        ended_at: Time.now,
      )
      result = Suma::Mobility::EndTripResult.new(
        undiscounted_cost: money("$6"),
        charge_at: Time.now,
        line_items: [Suma::Mobility::EndTripResult::LineItem.new(memo: "hi", amount: money("$2"))],
      )
      trip.charge_trip(result)
      expect(trip).to be_saved
      expect(trip.charge).to have_attributes(
        discounted_subtotal: cost("$2"),
        undiscounted_subtotal: cost("$6"),
      )
      expect(trip.charge.line_items).to contain_exactly(
        have_attributes(amount: cost("$2"), memo: have_attributes(en: "hi")),
      )
      expect(trip.charge.contributing_book_transactions).to contain_exactly(
        have_attributes(
          originating_ledger: member.payment_account.cash_ledger!,
          receiving_ledger: Suma::Payment::Account.lookup_platform_account.cash_ledger!,
          amount: cost("$2"),
        ),
      )
    end

    it "raises if the trip cost is negative" do
      result = Suma::Mobility::EndTripResult.new(
        charge_at: Time.now,
        undiscounted_cost: money("$6"),
        line_items: [Suma::Mobility::EndTripResult::LineItem.new(memo: "hi", amount: money("-$2"))],
      )
      expect do
        described_class.new.charge_trip(result)
      end.to raise_error(Suma::InvalidPrecondition, /negative trip cost/)
    end
  end

  describe "begin/end address" do
    it "parses into a part1 and part2" do
      trip = Suma::Fixtures.mobility_trip.create(
        begin_address: "123 Main St, New York, NY 10001",
        end_address: "456 Main St",
      )
      expect(trip.begin_address_parsed).to eq({part1: "123 Main St", part2: "New York, NY 10001"})
      expect(trip.end_address_parsed).to eq({part1: "456 Main St", part2: ""})
      trip.begin_address = trip.end_address = nil
      expect(trip.begin_address_parsed).to be_nil
      expect(trip.end_address_parsed).to be_nil
      trip.begin_address = trip.end_address = " "
      expect(trip.begin_address_parsed).to be_nil
      expect(trip.end_address_parsed).to be_nil
    end

    it "removes the country from part2" do
      trip = Suma::Fixtures.mobility_trip.create(
        begin_address: "123 Main St, New York, NY 10001, United States",
      )
      expect(trip.begin_address_parsed).to eq({part1: "123 Main St", part2: "New York, NY 10001"})
    end
  end

  describe "duration" do
    let(:t) { Time.parse("2000-01-01T00:00:00Z") }

    it "is nil if ongoing" do
      trip = Suma::Fixtures.mobility_trip(began_at: t).instance
      expect(trip).to have_attributes(duration: nil, duration_minutes: nil)
    end

    it "rounds up to the minute" do
      trip = Suma::Fixtures.mobility_trip(began_at: t, ended_at: t).instance
      expect(trip).to have_attributes(duration: 0, duration_minutes: 0)
      trip.ended_at = trip.began_at + 1
      expect(trip).to have_attributes(duration: 1, duration_minutes: 1)
      trip.ended_at = trip.began_at + 59
      expect(trip).to have_attributes(duration: 59, duration_minutes: 1)
      trip.ended_at = trip.began_at + 60
      expect(trip).to have_attributes(duration: 60, duration_minutes: 1)

      trip.ended_at = trip.began_at + 61
      expect(trip).to have_attributes(duration: 61, duration_minutes: 2)
      trip.ended_at = trip.began_at + 120
      expect(trip).to have_attributes(duration: 120, duration_minutes: 2)
      trip.ended_at = trip.began_at + 121
      expect(trip).to have_attributes(duration: 121, duration_minutes: 3)
    end
  end

  describe "validations" do
    it "fails if the member has multiple ongoing trips" do
      Suma::Fixtures.mobility_trip(member:).ended.create
      Suma::Fixtures.mobility_trip(member:).ongoing.create
      expect do
        Suma::Fixtures.mobility_trip(member:).ongoing.create
      end.to raise_error(Sequel::UniqueConstraintViolation, /one_active_ride_per_member/)
    end
    it "fails if end fields are not set together" do
      expect do
        Suma::Fixtures.mobility_trip(member:).ended.create(end_lat: nil)
      end.to raise_error(Sequel::ConstraintViolation, /end_fields_set_together/)
    end
  end
end
