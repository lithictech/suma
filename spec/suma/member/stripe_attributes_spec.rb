# frozen_string_literal: true

RSpec.describe Suma::Member::StripeAttributes, :db do
  let(:member) { Suma::Fixtures.member.create }

  describe "looking up the Stripe customer" do
    it "errors if the Suma customer is not registered" do
      expect { member.stripe.customer }.to raise_error(Suma::Stripe::CustomerNotRegistered)
    end

    it "returns the Stripe customer if registered" do
      member.stripe_customer_json = load_fixture_data("stripe/customer")
      expect(member.stripe.customer).to be_an_instance_of(Stripe::Customer)
    end
  end

  describe "customer registration" do
    let(:member) { Suma::Fixtures.member.create }

    it "knows if a Suma customer is already registred as a Stripe customer" do
      expect(member.stripe).to_not be_registered_as_customer
      member.stripe_customer_json = {"id" => "abc"}
      expect(member.stripe).to be_registered_as_customer
    end

    it "can register a Suma customer as a Stripe customer" do
      register_req = stub_request(:post, "https://api.stripe.com/v1/customers").
        with(body: hash_including(email: member.email), headers: {"Idempotency-Key" => /members-\d+-customer/i}).
        and_return(fixture_response("stripe/customer"))

      cust = member.stripe.register_as_customer

      expect(register_req).to have_been_made

      expect(cust.id).to eq("cus_D6eGmbqyejk8s9")
      expect(member.stripe.customer_id).to eq("cus_D6eGmbqyejk8s9")
      expect(member.stripe_customer_json).to include("id")
    end

    it "returns the fetched Stripe customer if the Suma customer is already registered" do
      member.stripe_customer_json = load_fixture_data("stripe/customer")

      cust = member.stripe.register_as_customer

      expect(cust.id).to eq("cus_D6eGmbqyejk8s9")
      expect(member.stripe.customer_id).to eq("cus_D6eGmbqyejk8s9")
    end
  end

  describe "charge card creation" do
    it "creates a card for a customer" do
      member = Suma::Fixtures.member.registered_as_stripe_customer.create
      url = "https://api.stripe.com#{member.stripe_customer_json['sources']['url']}"
      card_req = stub_request(:post, url).
        with(body: hash_including("source" => "tok_456")).
        to_return(fixture_response("stripe/card"))

      card = member.stripe.register_card_for_charges("tok_456")
      expect(card.id).to eq("card_1CgQyH2eZvKYlo2CYkDQhvma")

      expect(card_req).to have_been_made
    end
  end

  describe "charge creation" do
    let(:member) { Suma::Fixtures.member.registered_as_stripe_customer.create }
    let(:card) { Suma::Fixtures.card.member(member).create }

    it "charges the card" do
      req = stub_request(:post, "https://api.stripe.com/v1/charges").
        with(
          body: hash_including({"amount" => "200",
                                "currency" => "USD",
                                "customer" => member.stripe.customer_id,
                                "description" => "hi",
                                "source" => "card_1LxbQmAqRmWQecssc7Yf9Wr7",}),
          headers: {"Idempotency-Key" => "idk"},
        ).
        to_return(fixture_response("stripe/charge"))

      charge = member.stripe.charge_card(card:, amount: Money.new(200), memo: "hi", idempotency_key: "idk")
      expect(charge.id).to eq("ch_1Cgkfs2eZvKYlo2CVPsK4I3f")

      expect(req).to have_been_made
    end

    it "errors if the card does not belong to the member" do
      card = Suma::Fixtures.card.create
      expect do
        member.stripe.charge_card(card:, amount: Money.new(200), memo: "hi", idempotency_key: "idk")
      end.to raise_error(Suma::InvalidPrecondition)
    end
  end

  describe "card update" do
    let(:member) { Suma::Fixtures.member.registered_as_stripe_customer.create }
    let(:card) { Suma::Fixtures.card.member(member).create }

    it "updates the card" do
      url = "https://api.stripe.com/v1/customers/#{member.stripe.customer_id}/sources/card_1LxbQmAqRmWQecssc7Yf9Wr7"
      req = stub_request(:post, url).
        with(body: {"exp_month" => "12", "exp_year" => "2030"}).
        to_return(fixture_response("stripe/customer"))

      expect do
        member.stripe.update_card(card:, exp_month: "12", exp_year: "2030")
      end.to(change { member.updated_at })

      expect(req).to have_been_made
    end

    it "errors if the card does not belong to the member" do
      card = Suma::Fixtures.card.create
      expect do
        member.stripe.update_card(card:, exp_month: "12", exp_year: "2030")
      end.to raise_error(Suma::InvalidPrecondition)
    end
  end
end
