# frozen_string_literal: true

require "suma/behaviors"

RSpec.describe "Suma::Mobility::Trip", :db do
  let(:described_class) { Suma::Mobility::Trip }
  let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger(amount: money("$15")).create }
  let(:vendor_service) { Suma::Fixtures.vendor_service.mobility.create(external_name: "Super Scoot") }
  let(:rate) { Suma::Fixtures.vendor_service_rate.create }
  let(:t) { trunc_time(Time.now) }

  before(:each) do
    Suma::Mobility::VendorAdapter::Fake.reset
  end

  it "can be fixtured" do
    expect(Suma::Fixtures.mobility_trip.create).to be_a(described_class)
  end

  it_behaves_like "a type with a single image" do
    let(:instance) { Suma::Fixtures.mobility_trip.create }
  end

  describe "start_trip" do
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

    it "errors if the service prohibits usage" do
      member.update(onboarding_verified: false)
      v = Suma::Fixtures.mobility_vehicle.create
      expect do
        described_class.start_trip_from_vehicle(member:, vehicle: v, rate:)
      end.to raise_error(Suma::Member::ReadOnlyMode)
    end
  end

  describe "end_trip" do
    let!(:mobility_ledger) { Suma::Fixtures.ledger.member(member).category(:mobility).create }
    let!(:cash) { Suma::Vendor::ServiceCategory.find!(slug: "cash") }
    let!(:mobility) { Suma::Vendor::ServiceCategory.find!(slug: "mobility") }

    it "ends the trip and creates a charge using the returned cost" do
      Suma::Mobility::VendorAdapter::Fake.end_trip_callback = lambda do |etr|
        etr.cost = money("$1.20")
        etr.undiscounted = money("$1.62")
      end
      trip = Suma::Fixtures.mobility_trip.ongoing.create(member:)
      trip.end_trip(lat: 1, lng: 2, now: Time.now)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$1.62"),
        discounted_subtotal: cost("$1.20"),
      )
      expect(trip.charge.line_items).to contain_exactly(
        have_attributes(book_transaction: have_attributes(amount: cost("$1.20"))),
      )
    end

    it "charges the mobility ledger if there is a balance" do
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(20).create
      Suma::Fixtures.book_transaction.to(member.payment_account.mobility_ledger!).create(amount: money("$1"))
      trip = Suma::Fixtures.mobility_trip(vendor_service:).
        ongoing.
        create(began_at: t - 211.seconds, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2, now: t)
      expect(trip.refresh).to have_attributes(end_lat: 1, end_lng: 2)
      expect(trip.charge).to have_attributes(
        undiscounted_subtotal: cost("$0.80"),
        discounted_subtotal: cost("$0.80"),
      )
      expect(trip.charge.line_items.map(&:book_transaction)).to contain_exactly(
        have_attributes(
          originating_ledger: member.payment_account.mobility_ledger!,
          receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(mobility),
          amount: cost("$0.80"),
          memo: have_attributes(en: start_with("Super Scoot - trp_")),
          associated_vendor_service_category: be === mobility,
        ),
      )
    end

    it "charges the cash ledger if the mobility ledger cannot cover the full amount" do
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(20).create
      trip = Suma::Fixtures.mobility_trip(vendor_service:).
        ongoing.
        create(began_at: t - 211.seconds, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2, now: t)
      expect(trip.charge.line_items.map(&:book_transaction)).to contain_exactly(
        have_attributes(
          originating_ledger: member.payment_account.cash_ledger!,
          receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(cash),
          amount: cost("$0.80"),
          memo: have_attributes(en: start_with("Super Scoot - trp_")),
          associated_vendor_service_category: be === cash,
        ),
      )
      expect(trip.charge.associated_funding_transactions).to be_empty
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
          have_attributes(amount: cost("$185")),
        )
        expect(trip.charge.line_items.map(&:book_transaction)).to contain_exactly(
          have_attributes(
            originating_ledger: member.payment_account.cash_ledger!,
            receiving_ledger: Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(cash),
            amount: cost("$15"),
            memo: have_attributes(en: start_with("Super Scoot - trp_")),
            associated_vendor_service_category: be === cash,
          ),
        )
      end

      it "errors if there is no payment instrument" do
        expect { trip.end_trip(lat: 1, lng: 2, now: Time.now) }.to raise_error(/has no payment instrument/)
      end
    end

    it "does not create any book transactions for a $0 trip cost" do
      Suma::Payment.ensure_cash_ledger(member)
      member.refresh
      rate = Suma::Fixtures.vendor_service_rate.unit_amount(0).surcharge(0).create
      trip = Suma::Fixtures.mobility_trip.
        ongoing.
        create(began_at: 6.minutes.ago, vendor_service_rate: rate, member:)
      trip.end_trip(lat: 1, lng: 2, now: Time.now)
      expect(trip.charge).to have_attributes(discounted_subtotal: cost("$0"))
      expect(trip.charge.line_items).to be_empty
    end
  end

  describe "import_trip" do
    let(:began_at) { 30.minutes.ago }

    it "imports and charges the given trip" do
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
      charge = described_class.import_trip(trip, cost: money("$0"), undiscounted_subtotal: money("$6"))
      expect(trip).to be_saved
      expect(charge).to have_attributes(
        undiscounted_subtotal: cost("$6"),
      )
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
