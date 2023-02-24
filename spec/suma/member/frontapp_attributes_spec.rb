# frozen_string_literal: true

RSpec.describe Suma::Member::FrontappAttributes, :db do
  let(:member) { Suma::Fixtures.member.create }

  describe "upsert front contacts" do
    it "creates Front contact if member is missing contact id" do
      contact_req = stub_request(:post, "https://api2.frontapp.com/contacts").
        with(body: hash_including(
          "name" => member.name,
          "links" => [member.admin_link],
          "handles" => [
            {"source" => "phone", "handle" => member.phone},
            {"source" => "email", "handle" => member.email},
          ],
          "custom_fields" => {},
        )).to_return(fixture_response("front/contact"))

      member.frontapp.upsert_contact
      expect(member).to have_attributes(frontapp_contact_id: "crd_123")
      expect(contact_req).to have_been_made
    end

    it "updates Front contact if member contains contact id" do
      member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
      contact_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.frontapp_contact_id}").
        with(body: hash_including(
          "name" => member.name,
          "links" => [member.admin_link],
          "custom_fields" => {},
        )).to_return(status: 200)
      handles_url = "https://api2.frontapp.com/contacts/#{member.frontapp_contact_id}/handles"
      handle_req = stub_request(:post, handles_url).
        with(body: hash_including({"source" => "phone", "handle" => member.phone})).
        to_return(status: 200)
      handle_req2 = stub_request(:post, handles_url).
        with(body: hash_including({"source" => "email", "handle" => member.email})).
        to_return(status: 200)

      member.frontapp.upsert_contact
      expect(contact_req).to have_been_made
      expect(handle_req).to have_been_made
      expect(handle_req2).to have_been_made
    end

    it "does not add Front contact handles if member is missing them" do
      member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
      member.email = nil
      member.phone = nil
      contact_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.frontapp_contact_id}").
        with(body: hash_including(
          "name" => member.name,
          "links" => [member.admin_link],
          "custom_fields" => {},
        )).to_return(status: 200)

      member.frontapp.upsert_contact
      expect(contact_req).to have_been_made
    end
  end
end
