# frozen_string_literal: true

require "suma/frontapp"

RSpec.describe Suma::Frontapp do
  it "converts values to API ids" do
    expect(described_class.to_api_id("cnv", 1234)).to eq("cnv_ya")
    expect(described_class.to_api_id("cnv", "1234")).to eq("cnv_ya")
    expect(described_class.to_api_id("cnv", "cnv_1234")).to eq("cnv_1234")
    expect(described_class.to_api_id("cnv", "cnv_abc")).to eq("cnv_abc")
    expect(described_class.to_api_id("cnv", "")).to eq("")
    expect(described_class.to_api_id("cnv", nil)).to be_nil
    expect { described_class.to_api_id("cnv", "msg_123") }.to raise_exception(ArgumentError)
  end

  describe "make_http_request" do
    it "makes an http request" do
      req = stub_request(:post, "https://api2.frontapp.com/foo").
        with(
          body: '{"x":1}',
          headers: {
            "Accept" => "*/*",
            "Authorization" => "Bearer get-from-front-add-to-env",
            "Content-Type" => "application/json",
            "Y" => "z",
          },
        ).
        to_return(json_response({z: 1}))
      r = Suma::Frontapp.make_http_request(:post, "/foo", body: {x: 1}, headers: {"Y" => "z"})
      expect(req).to have_been_made
      expect(r.parsed_response).to eq({"z" => 1})
    end
  end

  # rubocop:disable Layout/LineLength
  describe "client shims" do
    before(:each) do
      allow(HTTP::FormData::Multipart).to receive(:generate_boundary).
        and_return("fakeboundary")
    end

    describe "create" do
      it "makes json requests for normal data" do
        req = stub_request(:post, "https://api2.frontapp.com//foo").
          with(
            body: "{\"x\":{\"y\":1}}",
            headers: {"Content-Type" => "application/json; charset=utf-8"},
          ).
          to_return(json_response({}))

        described_class.client.create("/foo", {x: {y: 1}})

        expect(req).to have_been_made
      end

      it "makes multipart requests for formdata values" do
        req = stub_request(:post, "https://api2.frontapp.com//foo").with do |r|
          expect(r.headers).to include("Content-Type" => "multipart/form-data; boundary=fakeboundary")
          expect(r.body).to eq("--fakeboundary\r\nContent-Disposition: form-data; name=\"x\"\r\n\r\ny\r\n--fakeboundary--\r\n")
        end.to_return(json_response({}))

        described_class.client.create("/foo", {x: HTTP::FormData::Part.new("y")})

        expect(req).to have_been_made
      end

      it "makes multipart requests for formdata arrays" do
        req = stub_request(:post, "https://api2.frontapp.com//foo").with do |r|
          expect(r.headers).to include("Content-Type" => "multipart/form-data; boundary=fakeboundary")
          expect(r.body).to eq("--fakeboundary\r\nContent-Disposition: form-data; name=\"x\"\r\n\r\ny\r\n--fakeboundary--\r\n")
        end.to_return(json_response({}))

        described_class.client.create("/foo", {x: [HTTP::FormData::Part.new("y")]})

        expect(req).to have_been_made
      end

      it "makes multipart requests for body keys with brackets" do
        req = stub_request(:post, "https://api2.frontapp.com//foo").with do |r|
          expect(r.headers).to include("Content-Type" => "multipart/form-data; boundary=fakeboundary")
          expect(r.body).to eq("--fakeboundary\r\nContent-Disposition: form-data; name=\"x[y]\"\r\n\r\n1\r\n--fakeboundary\r\nContent-Disposition: form-data; name=\"z\"\r\n\r\n2\r\n--fakeboundary--\r\n")
        end.to_return(json_response({}))

        described_class.client.create("/foo", {"x[y]" => 1, z: 2})

        expect(req).to have_been_made
      end
    end
  end
  # rubocop:enable Layout/LineLength
end
