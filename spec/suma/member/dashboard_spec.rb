# frozen_string_literal: true

require "suma/member/dashboard"

RSpec.describe Suma::Member::Dashboard, :db do
  let(:member) { Suma::Fixtures.member.create }
  let(:now) { Time.now }

  def dashboard = described_class.new(member, at: now)

  it "can represent a blank/empty member" do
    expect(dashboard).to have_attributes(cash_balance: money("$0"), program_enrollments: [])
  end

  it "includes enrolled programs" do
    pe1 = Suma::Fixtures.program_enrollment.create(member:)
    pe2 = Suma::Fixtures.program_enrollment.create(member:)
    expect(dashboard).to have_attributes(
      program_enrollments: have_same_ids_as(pe1, pe2),
    )
  end

  it "adds the member role by default" do
    dashboard.program_enrollments
    expect(member.roles).to include(Suma::Role.cache.member)
  end

  it "sorts enrollments by program ordinal" do
    p3 = Suma::Fixtures.program.create(ordinal: 3)
    p1 = Suma::Fixtures.program.create(ordinal: 1)
    p2 = Suma::Fixtures.program.create(ordinal: 2)
    pe3 = Suma::Fixtures.program_enrollment.create(member:, program: p3)
    pe1 = Suma::Fixtures.program_enrollment.create(member:, program: p1)
    pe2 = Suma::Fixtures.program_enrollment.create(member:, program: p2)
    enrollments = dashboard.program_enrollments
    expect(enrollments.first).to have_attributes(program: p1)
    expect(enrollments.second).to have_attributes(program: p2)
    expect(enrollments.last).to have_attributes(program: p3)
  end

  describe "alerts" do
    before(:each) do
      Suma::Payment.ensure_cash_ledger(member)
    end

    def add_valid_card = Suma::Fixtures.card.member(member).create

    def add_expired_card = Suma::Fixtures.card.member(member).expired.create

    def make_eligible_for_expiring_card_warning
      # Memmber dataset requires a mobility trip
      Suma::Fixtures.mobility_trip.create(member: member)
      Suma::Fixtures.card.member(member).expiring.create
    end

    def make_balance_negative
      Suma::Fixtures.book_transaction.from(member.payment_account!.cash_ledger!).create
    end

    it "has no alerts by default" do
      expect(dashboard.alerts).to be_empty
    end

    it "warns about negative cash balance (instruments available)" do
      add_valid_card
      make_balance_negative
      expect(dashboard.alerts).to contain_exactly(
        have_attributes(localization_key: "dashboard.negative_cash_balance", variant: "danger"),
      )
    end

    it "warns about negative cash balance (no/expired instruments available)" do
      add_expired_card
      make_balance_negative
      expect(dashboard.alerts).to contain_exactly(
        have_attributes(localization_key: "dashboard.negative_cash_balance_no_instrument", variant: "danger"),
      )
    end

    it "tells the user about expiring payment instruments" do
      make_eligible_for_expiring_card_warning
      expect(dashboard.alerts).to contain_exactly(
        have_attributes(localization_key: "dashboard.payment_methods_expiring", variant: "warning"),
      )
    end
  end
end
