# frozen_string_literal: true

require "suma/admin_api/members"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Members, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/members" do
    it "returns all members" do
      u = Array.new(2) { Suma::Fixtures.member.create }

      get "/v1/members"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(admin, *u))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/members" }
      let(:search_term) { "ZIM" }

      def make_matching_items
        return [
          Suma::Fixtures.member(email: "zim@zam.zom").create,
          Suma::Fixtures.member(name: "Zim Zam").create,
        ]
      end

      def make_non_matching_items
        return [
          admin,
          Suma::Fixtures.member(name: "wibble wobble", email: "qux@wux").create,
        ]
      end
    end

    describe "search" do
      it "can search phone number" do
        match = Suma::Fixtures.member(phone: "12223334444").create
        nommatch = Suma::Fixtures.member(phone: "12225554444").create

        get "/v1/members", search: "22333444"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(match))
      end

      it "only searches phone if search term has only numbers" do
        match = Suma::Fixtures.member(email: "holt17510@hotmail.com", phone: "15319990165").create
        nommatch = Suma::Fixtures.member(email: "nonsense@hotmail.com", phone: "17519910205").create

        get "/v1/members", search: "holt1751"

        expect(last_response).to have_status(200)
        expect(last_response).to have_json_body.that_includes(items: have_same_ids_as(match))
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/members" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return admin.update(created_at: created) if i.zero?
        return Suma::Fixtures.member.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/members" }
      let(:order_by_field) { "note" }
      def make_item(i)
        return admin.update(note: i.to_s) if i.zero?
        return Suma::Fixtures.member.create(created_at: Time.now + rand(1..100).days, note: i.to_s)
      end
    end
  end

  describe "GET /v1/members/:id" do
    it "returns the member" do
      get "/v1/members/#{admin.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(:roles, id: admin.id)
    end

    it "403s if the member does not exist" do
      get "/v1/members/0"

      expect(last_response).to have_status(403)
    end

    it "represents detailed info" do
      Suma::Fixtures.session(member: admin, peer_ip: "1.2.3.4").create
      cash_ledger = Suma::Fixtures.ledger.member(admin).category(:cash).create
      charge1 = Suma::Fixtures.charge(member: admin).create
      charge1.add_book_transaction(Suma::Fixtures.book_transaction.from(cash_ledger).create)

      get "/v1/members/#{admin.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        sessions: contain_exactly(include(ip_lookup_link: "https://whatismyipaddress.com/ip/1.2.3.4")),
      )
    end
  end

  describe "POST /v1/members/:id" do
    it "updates the member" do
      member = Suma::Fixtures.member.create

      post "/v1/members/#{member.id}", name: "b 2", email: "b@gmail.com"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(id: member.id, name: "b 2", email: "b@gmail.com")
    end

    it "replaces roles" do
      member = Suma::Fixtures.member.with_role("existing").with_role("to_remove").create
      Suma::Role.create(name: "to_add")

      post "/v1/members/#{member.id}", roles: ["existing", "to_add"]

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(roles: contain_exactly("existing", "to_add"))
      expect(member.refresh.roles.map(&:name)).to contain_exactly("existing", "to_add")
    end
  end

  describe "POST /v1/members/:id/close" do
    it "soft deletes the member" do
      member = Suma::Fixtures.member.create
      post "/v1/members/#{member.id}/close"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: member.id, soft_deleted_at: be_present)
      expect(member.refresh).to be_soft_deleted
    end

    it "does not re-delete" do
      orig_at = 2.hours.ago
      member = Suma::Fixtures.member.create(soft_deleted_at: orig_at)

      post "/v1/members/#{member.id}/close"

      expect(last_response).to have_status(200)
      expect(member.refresh.soft_deleted_at).to be_within(1).of(orig_at)
    end

    it "adds an activity" do
      member = Suma::Fixtures.member.create
      post "/v1/members/#{member.id}/close"

      expect(last_response).to have_status(200)
      expect(Suma::Member.last.activities).to contain_exactly(have_attributes(message_name: "accountclosed"))
    end
  end
end
