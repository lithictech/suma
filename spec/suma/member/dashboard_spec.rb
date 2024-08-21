# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.create }
  let(:now) { Time.now }

  it "can represent a blank/empty member" do
    d = described_class.new(member, at: now)
    expect(d).to have_attributes(
      payment_account_balance: cost("$0"),
      lifetime_savings: cost("$0"),
      ledger_lines: be_empty,
    )
  end

  it "can represent a member with ledgers and transactions" do
    cash_ledger = Suma::Fixtures.ledger.member(member).category(:cash).create
    grocery_ledger = Suma::Fixtures.ledger.member(member).category(:food).create
    # Add charges, one with transactions
    charge1 = Suma::Fixtures.charge(member:).create(undiscounted_subtotal: money("$30"))
    charge1.add_book_transaction(
      Suma::Fixtures.book_transaction.from(cash_ledger).create(amount: money("$20"), apply_at: 20.days.ago),
    )
    charge1.add_book_transaction(
      Suma::Fixtures.book_transaction.from(grocery_ledger).create(amount: money("$5"), apply_at: 21.days.ago),
    )
    charge2 = Suma::Fixtures.charge(member:).create(undiscounted_subtotal: money("$4.31"))
    # Add book transactions for funding events
    Suma::Fixtures.book_transaction.to(cash_ledger).create(amount: money("$27"))
    d = described_class.new(member, at: now)
    expect(d).to have_attributes(
      payment_account_balance: cost("$2"),
      lifetime_savings: cost("$9.31"),
      ledger_lines: match(
        [
          have_attributes(amount: cost("$27")),
          have_attributes(amount: cost("-$20")),
          have_attributes(amount: cost("-$5")),
        ],
      ),
      offerings: [],
      mobility_available?: false,
    )
  end

  it "includes the two offerings closing next" do
    ec = Suma::Fixtures.eligibility_constraint.create
    member.add_verified_eligibility_constraint(ec)
    member.update(onboarding_verified_at: 2.minutes.ago)
    ofac = Suma::Fixtures.offering.with_constraints(ec)
    ofac.closed.description("closed").create
    middle = ofac.description("middle ahead").create(period: 1.day.ago..10.days.from_now)
    closest = ofac.description("closest").create(period: 1.day.ago..7.days.from_now)
    ofac.description("furthest ahead").create(period: 1.day.ago..11.days.from_now)

    d = described_class.new(member, at: now)
    expect(d).to have_attributes(next_offerings: have_same_ids_as(closest, middle).ordered)
  end

  it "includes whether vehicles are available" do
    ec = Suma::Fixtures.eligibility_constraint.create
    member.add_verified_eligibility_constraint(ec)
    member.update(onboarding_verified_at: 2.minutes.ago)

    vendor_service = Suma::Fixtures.vendor_service.mobility.with_constraints(ec).create
    expect(described_class.new(member, at: now)).to_not be_mobility_available

    Suma::Fixtures.mobility_vehicle.escooter.create(vendor_service:)
    expect(described_class.new(member, at: now)).to be_mobility_available

    vendor_service.update(period_end: 2.minutes.ago)
    expect(described_class.new(member, at: now)).to_not be_mobility_available
  end

  it "includes vendible groupings for eligible vendor services and offerings" do
    vs = Suma::Fixtures.vendor_service.mobility.create
    off = Suma::Fixtures.offering.create
    vg1 = Suma::Fixtures.vendible_group.with_(vs).create
    vg2 = Suma::Fixtures.vendible_group.with_(vs).create
    expect(described_class.new(member, at: now)).to have_attributes(
      vendible_groupings: contain_exactly(
        have_attributes(group: vg1),
        have_attributes(group: vg2),
      ),
    )
  end
end
