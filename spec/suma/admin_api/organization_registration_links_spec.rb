# frozen_string_literal: true

require "suma/admin_api/organization_registration_links"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::OrganizationRegistrationLinks, :db do
  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create(email: "z@mysuma.org") }

  before(:each) do
    login_as(admin)
  end

  describe "GET /v1/organization_registration_links" do
    it "returns all rows" do
      registration_links = Array.new(2) { Suma::Fixtures.registration_link.create }
      get "/v1/organization_registration_links"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*registration_links))
    end

    it_behaves_like "an endpoint capable of search" do
      let(:url) { "/v1/organization_registration_links" }
      let(:search_term) { "zzz" }

      def make_matching_items
        return [
          Suma::Fixtures.registration_link.create(organization: Suma::Fixtures.organization.create(name: "zzz")),
        ]
      end

      def make_non_matching_items
        return [
          Suma::Fixtures.registration_link.create(organization: Suma::Fixtures.organization.create(name: "wibble")),
        ]
      end
    end
  end

  describe "GET /v1/organization_registration_links/:id" do
    it "returns an instance" do
      link = Suma::Fixtures.registration_link.create

      get "/v1/organization_registration_links/#{link.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(id: link.id)
    end

    it "403s if the item does not exist" do
      get "/v1/organization_registration_links/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "POST /v1/organization_registration_links/create" do
    let(:org) { Suma::Fixtures.organization.create(name: "Z") }

    it "creates a link" do
      post "/v1/organization_registration_links/create", organization: {id: org.id}, intro: {en: "tk", es: "tk"}

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Created-Resource-Admin")
      expect(Suma::Organization::RegistrationLink.all).to contain_exactly(
        have_attributes(organization: include(id: org.id)),
      )
      link = Suma::Organization::RegistrationLink.first
      expect(org.audit_activities).to contain_exactly(
        have_attributes(
          # rubocop:disable Layout/LineLength
          summary: "z@mysuma.org performed reglink on Suma::Organization[#{org.id}] 'Z': RegistrationLink #{link.id}, ical_event=",
          # rubocop:enable Layout/LineLength
        ),
      )
    end
  end

  describe "POST /v1/organization_registration_links/:id" do
    it "can update the vevent" do
      link = Suma::Fixtures.registration_link.create
      ical_event = "DTSTART:20250418T000000Z\nDTEND:20250418T010000Z\n"
      post("/v1/organization_registration_links/#{link.id}", ical_event:)

      expect(last_response).to have_status(200)
      expect(link.refresh).to have_attributes(ical_event: "BEGIN:VEVENT\n#{ical_event}END:VEVENT\n")
    end
  end

  describe "DELETE /v1/organization_registration_links/:id" do
    it "deletes the vevent" do
      link = Suma::Fixtures.registration_link.create

      post "/v1/organization_registration_links/#{link.id}/destroy"

      expect(last_response).to have_status(200)
      expect(link).to be_destroyed
    end
  end
end
