# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/integration"

RSpec.describe Suma::Tasks::Integration, :db do
  include Suma::SpecHelpers::Rake

  describe "integration:lyftpass" do
    let(:vendor_service_rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:vendor_service) do
      Suma::Fixtures.vendor_service.
        mobility.
        create(
          mobility_vendor_adapter_key: "lyft_deeplink",
          charge_after_fulfillment: true,
        )
    end
    let(:program) do
      Suma::Fixtures.program(lyft_pass_program_id: "5678").with_pricing(vendor_service:, vendor_service_rate:).create
    end

    it "runs the sync" do
      Suma::Lyft.reset_configuration
      Suma::ExternalCredential.create(
        service: "lyft-pass-access-token",
        expires_at: 5.hours.from_now,
        data: {body: {}, cookies: {}}.to_json,
      )
      Suma::Lyft.pass_authorization = "Basic xyz"
      Suma::Lyft.pass_email = "a@b.c"
      Suma::Lyft.pass_org_id = "1234"
      _ = program

      program_req = stub_request(:post, "https://www.lyft.com/api/rideprograms/ride-program").
        to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {ride_program: {owner: {id: "9999"}}}.to_json,
        )
      rides_req = stub_request(:post, "https://www.lyft.com/v1/enterprise-insights/search/transactions?organization_id=1234&start_time=1546300800000").
        to_return(
          status: 200,
          headers: {"Content-Type" => "application/json"},
          body: {results: []}.to_json,
        )
      invoke_rake_task("integration:lyftpass")
      expect(program_req).to have_been_made
      expect(rides_req).to have_been_made
    end
  end
end
