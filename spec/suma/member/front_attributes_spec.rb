# frozen_string_literal: true

RSpec.describe Suma::Member::FrontAttributes, :db do
  let(:member) { Suma::Fixtures.member.create }

  describe "upsert front contacts" do
    it "creates Front contact if member is missing contact id" do
      contact_req = stub_request(:post, "https://api2.frontapp.com/contacts").
        with(body: hash_including({
                                    "name" => member.name,
                                    "links" => [member.admin_link],
                                    "handles" => [
                                      {"source" => "phone", "handle" => member.phone},
                                      {"source" => "email", "handle" => member.email},
                                    ],
                                    "custom_fields" => {},
                                  })).
        to_return(fixture_response("front/contact"))

      contact = member.front.create_contact({
                                              name: member.name,
                                              links: [member.admin_link],
                                              handles: [
                                                {source: "phone", handle: member.phone},
                                                {source: "email", handle: member.email},
                                              ],
                                              custom_fields: {},
                                            })
      expect(contact.fetch("id")).to eq("crd_123")
      expect(member.front.contact_id).to eq("crd_123")

      expect(contact_req).to have_been_made
    end

    it "updates Front contact if member contains contact id" do
      member = Suma::Fixtures.member.with_front_contact_id.create
      contact_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.front_contact_id}").
        with(body: hash_including({
                                    "name" => "some name",
                                    "links" => [member.admin_link],
                                  })).
        to_return(status: 200)

      response = member.front.update_contact({
                                               name: "some name",
                                               links: [member.admin_link],
                                             })
      # Front response does not return content
      expect(response).to be_nil

      expect(contact_req).to have_been_made
    end

    it "adds handles to Front contact" do
      member = Suma::Fixtures.member.with_front_contact_id.create
      url = "https://api2.frontapp.com/contacts/#{member.front_contact_id}/handles"
      handle_req = stub_request(:post, url).
        with(body: hash_including({"source" => "phone", "handle" => member.phone})).
        to_return(status: 200)
      handle_req2 = stub_request(:post, url).
        with(body: hash_including({"source" => "email", "handle" => member.email})).
        to_return(status: 200)

      handles = member.front.add_contact_handles
      expect(handles).to have_length(2)

      expect(handle_req).to have_been_made
      expect(handle_req2).to have_been_made
    end

    it "does not add Front contact handles if member is missing them" do
      member = Suma::Fixtures.member.with_front_contact_id.create
      member.email = nil
      member.phone = nil

      handle = member.front.add_contact_handles
      expect(handle).to be_nil
    end
  end
end
