# frozen_string_literal: true

require "suma/admin_api/anon_proxy"
require "suma/api/behaviors"

RSpec.describe Suma::AdminAPI::AnonProxy, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:admin) { Suma::Fixtures.member.admin.create }

  before(:each) do
    login_as_admin(admin)
  end

  describe "GET /v1/anon_proxy/vendor_accounts" do
    it "returns all anon proxy vendor accounts" do
      objs = Array.new(2) { Suma::Fixtures.anon_proxy_vendor_account.create }

      get "/v1/anon_proxy/vendor_accounts"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(items: have_same_ids_as(*objs))
    end
  end

  describe "GET /v1/anon_proxy/vendor_account/:id" do
    it "returns the anon proxy vendor account" do
      configuration = Suma::Fixtures.anon_proxy_vendor_configuration.create
      va = Suma::Fixtures.anon_proxy_vendor_account.with_configuration(configuration).create
      puts va.inspect
      member_contact = Suma::Fixtures.anon_proxy_member_contact(email: "a@b.c", member: va.member).create
      va.update(contact: member_contact)

      get "/v1/anon_proxy/vendor_accounts/#{va.id}"

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.that_includes(
        id: va.id,
        configuration: include(id: configuration.id),
        contact: include(id: member_contact.id),
      )
    end
  end
  #
  # describe "POST /v1/eligibility_constraints/:id" do
  #   it "updates the constraint" do
  #     ec = Suma::Fixtures.eligibility_constraint.create
  #     post "/v1/eligibility_constraints/#{ec.id}", name: "Test"
  #
  #     expect(last_response).to have_status(200)
  #     expect(last_response.headers).to include("Created-Resource-Admin")
  #     expect(ec.refresh).to have_attributes(name: "Test")
  #   end
  # end
end
