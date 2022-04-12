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

  describe "end_trip" do
    it "ends the trip" do
      ongoing = Suma::Fixtures.mobility_trip(customer:).ongoing.create
      ongoing.end_trip(lat: 1, lng: 2, at: t + 5)
      expect(ongoing.refresh).to have_attributes(
        end_lat: 1, end_lng: 2, ended_at: t + 5,
      )
    end
    it "creates a charge using the linked rate" do
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
