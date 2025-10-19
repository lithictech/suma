# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::BankAccount", :db do
  let(:described_class) { Suma::Payment::BankAccount }

  it_behaves_like "a payment instrument"

  it "knows when it is usable for funding and payouts" do
    ba = Suma::Fixtures.bank_account.create
    expect(ba).to have_attributes(usable_for_funding?: false, usable_for_payout?: true)
    expect(described_class.usable_for_funding.all).to be_empty
    expect(described_class.usable_for_payout.all).to have_same_ids_as(ba)

    ba.verified = true
    expect(ba).to have_attributes(usable_for_funding?: true, usable_for_payout?: true)
    ba.save_changes
    expect(described_class.usable_for_funding.all).to have_same_ids_as(ba)
    expect(described_class.usable_for_payout.all).to have_same_ids_as(ba)
  end

  it "knows it can never expire" do
    ba = Suma::Fixtures.bank_account.create
    expect(described_class.unexpired_as_of(Time.now).all).to have_same_ids_as(ba)
    expect(described_class.expired_as_of(Time.now).all).to be_empty
  end

  describe "verified" do
    it "is a timestamp accessor" do
      ba = Suma::Fixtures.bank_account.create
      expect(ba).to_not be_verified
      ba.verified = true
      expect(ba.verified_at).to match_time(:now)
      expect(ba).to be_verified
    end
  end

  it "finds or updates associated plaid institution when routing number is changed" do
    inst1 = Suma::Fixtures.plaid_institution.create(routing_numbers: ["111222333", "111222444"])
    inst2 = Suma::Fixtures.plaid_institution.create(routing_numbers: ["444555666"])
    ba = Suma::Fixtures.bank_account(routing_number: "111222444").create
    expect(ba.plaid_institution).to be === inst1
    ba.update(routing_number: "444555666")
    expect(ba.plaid_institution).to be === inst2
    ba.update(routing_number: "999555666")
    expect(ba.plaid_institution).to be_nil
  end

  describe "display" do
    it "uses a default rendering if there is no Plaid institution" do
      ba = Suma::Fixtures.bank_account(account_number: "1234567", name: "Checking").create
      expect(ba).to have_attributes(
        institution: have_attributes(
          name: "Unknown",
          logo_src: "",
          color: "#000000",
        ),
        name: "Checking",
        last4: "4567",
        simple_label: "Checking x-4567",
        admin_label: "Checking x-4567 (Unknown)",
      )
    end

    it "pulls the rendering from the Plaid institution if available" do
      Suma::Fixtures.plaid_institution.create(
        name: "Chase",
        logo_base64: "xyz",
        primary_color_hex: "red",
        routing_numbers: ["111333444"],
      )
      ba = Suma::Fixtures.bank_account(account_number: "1234567", routing_number: "111333444", name: "Checking").create
      expect(ba).to have_attributes(
        institution: have_attributes(
          name: "Chase",
          logo_src: "xyz",
          color: "red",
        ),
        name: "Checking",
        last4: "4567",
        simple_label: "Checking x-4567",
        admin_label: "Checking x-4567 (Chase)",
      )
    end

    it "has a masked account number" do
      ba = Suma::Fixtures.bank_account.instance(account_number: "123456789")
      expect(ba.masked_account_number).to eq("****6789")
      ba.account_number = "123"
      expect(ba.masked_account_number).to eq("****123")
      ba.account_number = ""
      expect(ba.masked_account_number).to eq("****")
    end
  end

  describe "validations" do
    it "errors for duplicate undeleted bank accounts" do
      member = Suma::Fixtures.member.create
      fac = Suma::Fixtures.bank_account(routing_number: "011401533", account_number: "9900009606").member(member)
      fac.create.soft_delete
      fac.create
      expect { fac.create }.to raise_error(
        Sequel::UniqueConstraintViolation,
      )
    end
  end
end
