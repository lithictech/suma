# frozen_string_literal: true

RSpec.describe "Suma::Mobility::Trip", :db do
  let(:described_class) { Suma::Mobility::Trip }
  let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$15")).create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create(external_name: "Super Scoot") }
  let(:rate) { Suma::Fixtures.vendor_service_rate.create }
  let(:t) { trunc_time(Time.now) }

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_trip.create).to be_a(described_class)
  end

  describe "start_trip" do
    it "creates a trip with the given parameters" do
      trip = described_class.start_trip(
        member:,
        vehicle_id: "abcd",
        vendor_service:,
        rate:,
        lat: 1.5,
        lng: 2.5,
        at: t,
      )
      expect(trip).to have_attributes(
        member:,
        vehicle_id: "abcd",
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
        trip = described_class.start_trip(
          member:,
          vehicle_id: "abcd",
          vendor_service:,
          rate:,
          lat: 1.5,
          lng: 2.5,
          at: t,
        )
      end.to raise_error(described_class::OngoingTrip)
    end
  end

  describe "start_trip_from_vehicle" do
    it "uses vehicle params for the trip" do
      v = Suma::Fixtures.mobility_vehicle.create
      trip = described_class.start_trip_from_vehicle(member:, vehicle: v, rate:)
      expect(trip).to have_attributes(
        vehicle_id: v.vehicle_id,
        vendor_service: be === v.vendor_service,
        begin_lat: v.lat,
        begin_lng: v.lng,
      )
    end

    it "errors if the eligible account balance is negative" do
      Suma::Fixtures.book_transaction.from(member.payment_account.ledgers.first).create(amount: money("$100"))
      v = Suma::Fixtures.mobility_vehicle.create
      expect do
        described_class.start_trip_from_vehicle(member:, vehicle: v, rate:)
      end.to raise_error(Suma::Member::ReadOnlyMode)
    end
  end

  describe "end_trip" do
    let!(:member_ledger) { Suma::Fixtures.ledger.member(member).category(:mobility).create }

    it "ends the trip and creates a charge using the linked rate" do
      rate = Suma::Fixtures.vendor_service_rate.
        unit_amount(20).
        discounted_by(0.25).
        create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$1.62"),
        discounted_subtotal: cost("$1.20"),
      )
      expect(trip.charge.book_transactions).to have_length(1)
    end

    it "uses the actual charge if there is no discount" do
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(20).create
      trip = Suma::Fixtures.mobility_trip(vendor_service:).
        ongoing.
        create(began_at: 211.seconds.ago, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$0.70"),
        discounted_subtotal: cost("$0.70"),
      )
      mobility = Suma::Vendor::ServiceCategory.find!(slug: "mobility")
      expect(trip.charge.book_transactions).to contain_exactly(
        have_attributes(
          originating_ledger: member.payment_account.mobility_ledger!,
          receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(mobility),
          amount: cost("$0.70"),
          memo: have_attributes(en: "Suma Mobility - Super Scoot"),
          associated_vendor_service_category: be === mobility,
        ),
      )
    end

    it "creates a $0 transaction for a $0 trip" do
      Suma::Payment.ensure_cash_ledger(member)
      member.refresh
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(0).surcharge(0).create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2)
      expect(trip.charge).to have_attributes(discounted_subtotal: cost("$0"))
      expect(trip.charge.book_transactions).to contain_exactly(
        have_attributes(
          originating_ledger: member.payment_account.mobility_ledger!,
          amount: cost("$0"),
        ),
      )
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
