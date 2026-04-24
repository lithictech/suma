# frozen_string_literal: true

require "suma/api/registration_links"

RSpec.describe Suma::API::RegistrationLinks, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }

  describe "GET /v1/registration_links/<opaque_id>" do
    it "returns a redirect" do
      link = Suma::Fixtures.registration_link.create
      expect(Suma::Secureid).to receive(:rand_enc).and_return("xyz")

      get "/v1/registration_links/#{link.opaque_id}"

      expect(last_response).to have_status(302)
      expect(last_response.headers).to include(
        "location" => "http://localhost:22001/api/v1/registration_links/capture?suma_regcode=xyz",
      )
    end

    it "403s for an invalid code" do
      get "/v1/registration_links/0"

      expect(last_response).to have_status(403)
    end
  end

  describe "GET /v1/registration_links/capture?suma_regcode=<code>" do
    it "returns a redirect" do
      link = Suma::Fixtures.registration_link.create
      code = link.make_one_time_code

      get "/v1/registration_links/capture?suma_regcode=#{code}"

      expect(last_response).to have_status(302)
      expect(last_response.headers).to include("location" => "http://localhost:22004/partner-signup")
    end

    it "returns a redirect even if the code is invalid" do
      get "/v1/registration_links/capture?suma_regcode=abc"

      expect(last_response).to have_status(302)
      expect(last_response.headers).to include("location" => "http://localhost:22004/partner-signup")
    end

    it "400s if no suma_regcode" do
      get "/v1/registration_links/capture"

      expect(last_response).to have_status(400)
      expect(last_response).to have_json_body.
        that_includes(error: include(message: /:suma_regcode param is required/))
    end
  end
end
