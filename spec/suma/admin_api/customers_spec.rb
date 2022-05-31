# frozen_string_literal: true

require "suma/admin_api/customers"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Customers, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.customer.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/customers" do
    it "returns all customers" do
      u = Array.new(2) { Suma::Fixtures.customer.create }

      get "/v1/customers"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(admin, *u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/customers" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.customer(email: "zim@zam.zom").create,
          Suma::Fixtures.customer(name: "Zim Zam").create,
        ]
      end

      def make_non_matching_items
        return [
          admin,
          Suma::Fixtures.customer(name: "wibble wobble", email: "qux@wux").create,
        ]
      end
    end

    describe "search" do
      it "can search phone number" do
        match = Suma::Fixtures.customer(phone: "12223334444").create
        nommatch = Suma::Fixtures.customer(phone: "12225554444").create

        get "/v1/customers", search: "22333444"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(match))
      end

      it "only searches phone if search term has only numbers" do
        match = Suma::Fixtures.customer(email: "holt17510@hotmail.com", phone: "15319990165").create
        nommatch = Suma::Fixtures.customer(email: "nonsense@hotmail.com", phone: "17519910205").create

        get "/v1/customers", search: "holt1751"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(match))
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/customers" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return admin.update(created_at: created) if i.zero?
        return Suma::Fixtures.customer.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with customer-supplied ordering" do
      let(:url) { "/v1/customers" }
      let(:order_by_field) { "note" }
      def make_item(i)
        return admin.update(note: i.to_s) if i.zero?
        return Suma::Fixtures.customer.create(created_at: Time.now + rand(1..100).days, note: i.to_s)
      end
    end
  end

  describe "GET /v1/customers/:id" do
    it "returns the customer" do
      get "/v1/customers/#{admin.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(:roles, id: admin.id)
    end

    it "404s if the customer does not exist" do
      get "/v1/customers/0"

      expect(last_response).to have_status(404)
    end

    it "represents sessions" do
      Suma::Fixtures.session(customer: admin, peer_ip: "1.2.3.4").create

      get "/v1/customers/#{admin.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        sessions: contain_exactly(include(ip_lookup_link: "https://whatismyipaddress.com/ip/1.2.3.4")),
      )
    end
  end

  describe "POST /v1/customers/:id" do
    it "updates the customer" do
      customer = Suma::Fixtures.customer.create

      post "/v1/customers/#{customer.id}", name: "b 2", email: "b@gmail.com"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: customer.id, name: "b 2", email: "b@gmail.com")
    end

    it "replaces roles" do
      customer = Suma::Fixtures.customer.with_role("existing").with_role("to_remove").create
      Suma::Role.create(name: "to_add")

      post "/v1/customers/#{customer.id}", roles: ["existing", "to_add"]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(roles: contain_exactly("existing", "to_add"))
      expect(customer.refresh.roles.map(&:name)).to contain_exactly("existing", "to_add")
    end
  end

  describe "POST /v1/customers/:id/close" do
    it "soft deletes the customer" do
      customer = Suma::Fixtures.customer.create
      post "/v1/customers/#{customer.id}/close"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: customer.id, soft_deleted_at: be_present)
      expect(customer.refresh).to be_soft_deleted
    end

    it "does not re-delete" do
      orig_at = 2.hours.ago
      customer = Suma::Fixtures.customer.create(soft_deleted_at: orig_at)

      post "/v1/customers/#{customer.id}/close"

      expect(last_response).to have_status(200)
      expect(customer.refresh.soft_deleted_at).to be_within(1).of(orig_at)
    end

    it "adds an activity" do
      customer = Suma::Fixtures.customer.create
      post "/v1/customers/#{customer.id}/close"

      expect(last_response).to have_status(200)
      expect(Suma::Customer.last.activities).to contain_exactly(have_attributes(message_name: "accountclosed"))
    end
  end

  describe "GET /v1/customers/:id/bank_accounts" do
    it "returns customer bank accounts" do
      c = Suma::Fixtures.customer.create
      o = Suma::Fixtures.bank_account.customer(c).create

      get "/v1/customers/#{c.id}/bank_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o))
    end
  end

  describe "GET /v1/customers/:id/payment_instruments" do
    it "returns customer bank accounts" do
      c = Suma::Fixtures.customer.create
      o1 = Suma::Fixtures.bank_account.customer(c).create

      get "/v1/customers/#{c.id}/payment_instruments"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(o1).ordered)
    end
  end
end
