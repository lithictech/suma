# frozen_string_literal: true

RSpec.describe "Suma::Mobility::Trip", :db do
  let(:described_class) { Suma::Mobility::Trip }
  let(:customer) { Suma::Fixtures.customer.create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.create }
  let(:rate) { Suma::Fixtures.vendor_service_rate.create }
  let(:t) { trunc_time(Time.now) }

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_trip.create).to be_a(described_class)
  end

  describe "start_trip" do
    it "creates a trip with the given parameters" do
      trip = described_class.start_trip(
        customer:,
        vehicle_id: "abcd",
        vendor_service:,
        rate:,
        lat: 1.5,
        lng: 2.5,
        at: t,
      )
      expect(trip).to have_attributes(
        customer:,
        vehicle_id: "abcd",
        vendor_service:,
        vendor_service_rate: rate,
        begin_lat: 1.5,
        begin_lng: 2.5,
        began_at: t,
      )
    end
    it "errors if the customer already has an ongoing trip" do
      ongoing = Suma::Fixtures.mobility_trip(customer:).ongoing.create
      expect do
        trip = described_class.start_trip(
          customer:,
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
      cash_ledger = Suma::Fixtures.ledger.customer(customer).category(:cash).create
      Suma::Fixtures.book_transaction.to(cash_ledger).create
      v = Suma::Fixtures.mobility_vehicle.create
      trip = described_class.start_trip_from_vehicle(customer:, vehicle: v, rate:)
      expect(trip).to have_attributes(
        vehicle_id: v.vehicle_id,
        vendor_service: be === v.vendor_service,
        begin_lat: v.lat,
        begin_lng: v.lng,
      )
    end

    it "errors if the eligible account balance is negative" do
      Suma::Fixtures.payment_account.create(customer:)
      v = Suma::Fixtures.mobility_vehicle.create
      expect do
        described_class.start_trip_from_vehicle(customer:, vehicle: v, rate:)
      end.to raise_error(Suma::Payment::InsufficientFunds)
    end
  end

  describe "end_trip" do
    let!(:customer_ledger) { Suma::Fixtures.ledger.customer(customer).category(:mobility).create }

    it "ends the trip and creates a charge using the linked rate" do
      rate = Suma::Fixtures.vendor_service_rate.
        unit_amount(20).
        discounted_by(0.25).
        create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, customer:)
      trip.end_trip(lat: 1, lng: 2)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$1.62"),
        discounted_subtotal: cost("$1.20"),
      )
      expect(trip.charge.book_transactions).to have_length(1)
    end

    it "creates no transactions for a $0 trip" do
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(0).surcharge(0).create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, customer:)
      trip.end_trip(lat: 1, lng: 2)
      expect(trip.charge).to have_attributes(discounted_subtotal: cost("$0"))
      expect(trip.charge.book_transactions).to be_empty
    end
  end

  describe "validations" do
    it "fails if the customer has multiple ongoing trips" do
      Suma::Fixtures.mobility_trip(customer:).ended.create
      Suma::Fixtures.mobility_trip(customer:).ongoing.create
      expect do
        Suma::Fixtures.mobility_trip(customer:).ongoing.create
      end.to raise_error(Sequel::UniqueConstraintViolation, /one_active_ride_per_customer/)
    end
    it "fails if end fields are not set together" do
      expect do
        Suma::Fixtures.mobility_trip(customer:).ended.create(end_lat: nil)
      end.to raise_error(Sequel::ConstraintViolation, /end_fields_set_together/)
    end
  end
end
