# frozen_string_literal: true

require "suma/spec_helpers/rake"
require "suma/tasks/mobility"

RSpec.describe Suma::Tasks::Mobility, :db do
  include Suma::SpecHelpers::Rake

  describe "mobility:sync:lyftpass" do
    let(:vendor_service_rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:vendor_service) { Suma::Fixtures.vendor_service.mobility_deeplink.create }
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
      invoke_rake_task("mobility:sync:lyftpass")
      expect(program_req).to have_been_made
      expect(rides_req).to have_been_made
    end
  end

  describe "mobility:sync:limereport", reset_configuration: Suma::Lime do
    let(:member) { Suma::Fixtures.member.onboarding_verified.with_cash_ledger.create }
    let(:va) { Suma::Fixtures.anon_proxy_vendor_account.create(member:) }
    let(:mc) { Suma::Fixtures.anon_proxy_member_contact.email("m1@in.mysuma.org").create(member:) }
    let(:rate) { Suma::Fixtures.vendor_service_rate.create }
    let(:program) do
      Suma::Fixtures.program.with_pricing(
        vendor_service: Suma::Fixtures.vendor_service.mobility_deeplink.create,
        vendor_service_rate: rate,
      ).create
    end

    before(:each) do
      Suma::Lime.trip_report_vendor_configuration_id = va.configuration_id
      va.add_registration(external_program_id: mc.email)
      va.configuration.add_program(program)
      import_localized_backend_seeds
    end

    it "runs the sync using ARGF" do
      txt = <<~CSV
        TRIP_TOKEN,CONSEQUENCE,START_TIME,END_TIME,START_LATITUDE,START_LONGITUDE,END_LATITUDE,END_LONGITUDE,REGION_NAME,USER_TOKEN,USER_EMAIL,TRIP_DURATION_MINUTES,TRIP_DISTANCE_MILES,COST_TO_SUMA,UNLOCK_COST,DURATION_COST,COST_PER_MINUTE,LIME_ACCESS_COST,STANDARD_FEE,PERCENT_DISCOUNT_RATE,REFUNDED_FLAG,,,,,,
        RTOKEN1,,09/16/2025 12:01 AM,09/16/2025 12:43 AM,45.464916,-122.647268,45.465336,-122.647118,Portland,6TWQPKZDTVI44,m1@in.mysuma.org,15.00,0.23,$1.00,$0.50,$1.05,$0.07,$1.55,$6.88,77,N,,,,,,
      CSV
      invoke_rake_task("mobility:sync:limereport", argf: StringIO.new(txt))
      expect(Suma::Mobility::Trip.all).to have_length(1)
    end
  end
end
