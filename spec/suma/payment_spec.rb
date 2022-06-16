# frozen_string_literal: true

require "suma/payment"

RSpec.describe Suma::Payment, :db do
  describe "ensure_cash_ledger" do
    let(:member) { Suma::Fixtures.member.create }
    it "creates a payment account and cash ledger" do
      led = described_class.ensure_cash_ledger(member)
      expect(led.vendor_service_categories).to contain_exactly(have_attributes(name: "Cash"))
      expect(led).to be === member.payment_account.cash_ledger
      expect(led).to have_attributes(name: "Cash")
    end

    it "can reuse an existing cash ledger" do
      led1 = described_class.ensure_cash_ledger(member)
      member.refresh
      led2 = described_class.ensure_cash_ledger(member)
      expect(led2).to be === led1
      expect(led1).to be === member.payment_account.cash_ledger
    end
  end
end
