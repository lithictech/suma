# frozen_string_literal: true

require "suma/admin_api/short_urls"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::ShortUrls, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }
  let(:shortener) { Suma::UrlShortener.shortener }

  before(:each) do
    login_as(admin)
    shortener.dataset.delete
  end

  after(:all) do
    Suma::UrlShortener.shortener.dataset.delete
  end

  def insert(url, short_id: nil, now: Time.now)
    short_id ||= shortener.gen_short_id
    rows = shortener.dataset.returning.insert(short_id:, url:, inserted_at: now)
    return rows.first
  end

  describe "GET /v1/short_urls" do
    it "returns all items" do
      objs = Array.new(2) { insert("u") }

      get "/v1/short_urls"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end

    it_behaves_like "an endpoint capable of search", download: false do
      let(:url) { "/v1/short_urls" }
      let(:search_term) { "ZZZ" }

      def make_matching_items
        return [insert("Johns zzz Market")]
      end

      def make_non_matching_items
        return [insert("wibble wobble")]
      end
    end

    it_behaves_like "an endpoint with pagination", download: false do
      let(:url) { "/v1/short_urls" }
      def make_item(i)
        created = Time.now - i.days
        return insert("x", short_id: i.to_s, now: created)
      end
    end

    it_behaves_like "an endpoint with member-supplied ordering", download: false do
      let(:url) { "/v1/short_urls" }
      let(:order_by_field) { "short_id" }
      def make_item(i)
        return insert("x", short_id: i.to_s, now: Time.now + rand(1..100).days)
      end
    end
  end

  describe "POST /v1/short_urls/create" do
    it "creates a blank short url" do
      post "/v1/short_urls/create"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        short_id: have_length(be > 5), long_url: "",
      )
      expect(shortener.dataset.all).to have_length(1)
    end
  end

  describe "GET /v1/short_urls/:id" do
    it "returns the url" do
      u = insert("a", short_id: "b")

      get "/v1/short_urls/#{u[:id]}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(short_id: "b", long_url: "a")
    end

    it "403s if invalid" do
      get "/v1/short_urls/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/short_urls/:id" do
    it "updates the url" do
      u = insert("a", short_id: "b")

      post "/v1/short_urls/#{u[:id]}", short_id: "x", long_url: "y"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(short_id: "x", long_url: "y")
      expect(shortener.dataset[id: u[:id]]).to include(short_id: "x", url: "y")
    end

    it "generates a short id if blank" do
      u = insert("a", short_id: "b")

      post "/v1/short_urls/#{u[:id]}", short_id: " ", long_url: "z"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(short_id: have_attributes(length: be > 5), long_url: "z")
      expect(shortener.dataset[id: u[:id]]).to include(url: "z")
    end
  end
end
