# frozen_string_literal: true

require "suma/payment/behaviors"

RSpec.describe "Suma::Payment::BankAccount", :db do
  let(:described_class) { Suma::Payment::BankAccount }

  it_behaves_like "a payment instrument" do
    let(:instrument) { Suma::Fixtures.bank_account.create }
  end

  describe "dataset" do
    describe "usable" do
      it "is not soft deleted bank accounts" do
        deleted_ba = Suma::Fixtures.bank_account.create
        deleted_ba.soft_delete
        ba2 = Suma::Fixtures.bank_account.create
        ba1 = Suma::Fixtures.bank_account.create
        expect(Suma::Payment::BankAccount.usable.all).to have_same_ids_as(ba1, ba2)
      end
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
          logo: "",
          color: "#000000",
        ),
        name: "Checking",
        last4: "4567",
        simple_label: "Checking x-4567",
        admin_label: "Checking/4567 (Unknown)",
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
          logo: "xyz",
          color: "red",
        ),
        name: "Checking",
        last4: "4567",
        simple_label: "Checking x-4567",
        admin_label: "Checking/4567 (Chase)",
      )
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
