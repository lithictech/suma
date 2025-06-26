# frozen_string_literal: true

RSpec.describe Suma::SpecHelpers do
  describe "fixture_response" do
    it "sets headers based on the format" do
      resp = fixture_response(body: "{}", format: :json, headers: {"x" => "1"})
      expect(resp).to eq(
        {body: "{}", headers: {"content-type" => "application/json", "x" => "1"}, status: 200},
      )

      resp = fixture_response(body: "<hi />", format: :xml, headers: {"x" => "1"})
      expect(resp).to eq(
        {body: "<hi />", headers: {"content-type" => "application/xml", "x" => "1"}, status: 200},
      )
    end
  end
end
