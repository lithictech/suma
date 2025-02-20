# frozen_string_literal: true

require "suma/admin_api/charges"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::Charges, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as(admin)
  end

  def format_to_zone(t)
    return t.in_time_zone("UTC").strftime("%FT%T.%L%:z")
  end

  describe "GET /v1/charges" do
    it "returns all charges" do
      c1 = Suma::Fixtures.charge.create
      c2 = Suma::Fixtures.charge.create

      get "/v1/charges"

      expect(last_response).to have_status(200)
      expect(last_response_json_body[:items].first).to eq(
        {
          admin_link: "http://localhost:22014/charge/#{c2.id}",
          created_at: format_to_zone(c2.created_at),
          discounted_subtotal: {
            cents: 0,
            currency: Suma.default_currency,
          },
          id: c2.id,
          member: {
            admin_link: "http://localhost:22014/member/#{c2.member.id}",
            created_at: format_to_zone(c2.member.created_at),
            email: c2.member.email,
            id: c2.member.id,
            name: c2.member.name,
            phone: c2.member.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          opaque_id: c2.opaque_id,
          undiscounted_subtotal: {
            cents: c2.undiscounted_subtotal.cents,
            currency: Suma.default_currency,
          },
        },
      )

      expect(last_response_json_body[:items].last).to eq(
        {
          admin_link: "http://localhost:22014/charge/#{c1.id}",
          created_at: format_to_zone(c1.created_at),
          discounted_subtotal: {
            cents: 0,
            currency: Suma.default_currency,
          },
          id: c1.id,
          member: {
            admin_link: "http://localhost:22014/member/#{c1.member.id}",
            created_at: format_to_zone(c1.member.created_at),
            email: c1.member.email,
            id: c1.member.id,
            name: c1.member.name,
            phone: c1.member.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          opaque_id: c1.opaque_id,
          undiscounted_subtotal: {
            cents: c1.undiscounted_subtotal.cents,
            currency: Suma.default_currency,
          },
        },
      )
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/charges" }
      let(:search_term) { "abcd" }

      def make_matching_items
        return [Suma::Fixtures.charge(opaque_id: "abcdefg").create]
      end

      def make_non_matching_items
        return [Suma::Fixtures.charge(opaque_id: "wibble wobble").create]
      end
    end

    it_behaves_like "an endpoint with pagination" do
      let(:url) { "/v1/charges" }
      def make_item(i)
        # Sorting is newest first, so the first items we create need to the the oldest.
        created = Time.now - i.days
        return Suma::Fixtures.charge.create(created_at: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering" do
      let(:url) { "/v1/charges" }
      let(:order_by_field) { "opaque_id" }
      def make_item(i)
        return Suma::Fixtures.charge.create(
          created_at: Time.now + rand(1..100).days,
          opaque_id: i.to_s,
        )
      end
    end
  end

  describe "GET /v1/charges/:id" do
    it "returns the charge" do
      c = Suma::Fixtures.charge.create(member: Suma::Fixtures.member.create)
      # save_changes does not change the updated_at date
      c.save # rubocop:disable Sequel/SaveChanges

      get "/v1/charges/#{c.id}"

      expect(last_response).to have_status(200)
      expect(last_response_json_body).to eq(
        {
          admin_link: "http://localhost:22014/charge/#{c.id}",
          associated_funding_transactions: [],
          book_transactions: [],
          commerce_order: nil,
          created_at: format_to_zone(c.created_at),
          discounted_subtotal: {
            cents: 0,
            currency: Suma.default_currency,
          },
          external_links: [],
          id: c.id,
          member: {
            admin_link: "http://localhost:22014/member/#{c.member.id}",
            created_at: format_to_zone(c.member.created_at),
            email: c.member.email,
            id: c.member.id,
            name: c.member.name,
            phone: c.member.phone,
            soft_deleted_at: nil,
            timezone: "America/Los_Angeles",
          },
          mobility_trip: nil,
          opaque_id: c.opaque_id,
          undiscounted_subtotal: {
            cents: c.undiscounted_subtotal.cents,
            currency: Suma.default_currency,
          },
          updated_at: format_to_zone(c.updated_at),
        },
      )
    end

    it "403s if the item does not exist" do
      get "/v1/charges/0"

      expect(last_response).to have_status(403)
    end
  end
end
