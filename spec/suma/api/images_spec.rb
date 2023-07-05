# frozen_string_literal: true

require "suma/api/behaviors"
require "suma/api/images"

RSpec.describe Suma::API::Images, :db do
  include Rack::Test::Methods

  let(:app) { described_class.build_app }
  let(:member) { Suma::Fixtures.member.create }

  def photo_file = File.open(Suma::SpecHelpers::TEST_DATA_DIR + "images/photo.png", "rb")

  describe "GET /v1/images/missing" do
    it "returns the 'no image available' image" do
      get "/v1/images/missing"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Content-Type" => "image/png")
      expect(last_response.body).to eq(File.binread(Suma::DATA_DIR + "images/no-image-available.png"))
    end
  end

  describe "GET /v1/images/:sha256" do
    it "returns the image" do
      uf = Suma::Fixtures.uploaded_file.uploaded_file(photo_file).create

      get "/v1/images/#{uf.opaque_id}"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Content-Type" => "image/png")
      expect(last_response.body).to eq(photo_file.read)
    end

    it "can process the image" do
      uf = Suma::Fixtures.uploaded_file.uploaded_file(photo_file).create

      get "/v1/images/#{uf.opaque_id}", w: 10

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Content-Type" => "image/png")
      expect(last_response.body).to have_length(be > 1000)
    end

    it "can pass a format" do
      uf = Suma::Fixtures.uploaded_file.uploaded_file(photo_file).create

      get "/v1/images/#{uf.opaque_id}", w: 10, fmt: "jpeg"

      expect(last_response).to have_status(200)
      expect(last_response.headers).to include("Content-Type" => "image/jpeg")
      expect(last_response.body).to have_length(be > 1000)
    end
  end

  describe "POST /v1/images" do
    let(:member) { Suma::Fixtures.member.create }
    before(:each) do
      login_as(member)
    end

    it "uploads a file" do
      file = Rack::Test::UploadedFile.new(photo_file, "image/png", true)

      member.add_role Suma::Role.admin_role
      post "/v1/images", {file:}

      expect(last_response).to have_status(200)
      expect(last_response).to have_json_body.
        that_includes(
          :opaque_id,
          content_type: "image/png",
          content_length: be > 20_000,
          absolute_url: start_with("http://localhost:22001/api/v1/images/im_"),
        )
    end

    it "allows a user with the upload_files role" do
      file = Rack::Test::UploadedFile.new(photo_file, "image/png", true)

      member.add_role Suma::Role.upload_files_role
      post "/v1/images", {file:}

      expect(last_response).to have_status(200)
    end

    it "403s if the user does not have an allowed role" do
      file = Rack::Test::UploadedFile.new(photo_file, "image/png", true)

      post "/v1/images", {file:}

      expect(last_response).to have_status(403)
    end
  end
end
