# frozen_string_literal: true

RSpec.describe Suma::Member::FrontappAttributes, :db do
  let(:member) { Suma::Fixtures.member.create }

  describe "upsert front contacts" do
    context "when the member contact id is missing" do
      it "creates a Front contact" do
        contact_req = stub_request(:post, "https://api2.frontapp.com/contacts").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
            "handles" => [
              {"source" => "phone", "handle" => member.phone},
              {"source" => "email", "handle" => member.email},
            ],
          )).to_return(fixture_response("front/contact"))

        member.frontapp.upsert_contact
        expect(member).to have_attributes(frontapp_contact_id: "crd_123")
        expect(contact_req).to have_been_made
      end

      it "falls back to updating a contact if a ConflictError is raised" do
        create_req = stub_request(:post, "https://api2.frontapp.com/contacts").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
            "handles" => [
              {"source" => "phone", "handle" => member.phone},
              {"source" => "email", "handle" => member.email},
            ],
          )).to_return(fixture_response("front/contact_conflict_error", status: 409))
        update_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.frontapp.contact_id}").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
          )).to_return(status: 200)
        handles_url = "https://api2.frontapp.com/contacts/#{member.frontapp.contact_id}/handles"
        handle_req = stub_request(:post, handles_url).
          with(body: hash_including({"source" => "phone", "handle" => member.phone})).
          to_return(status: 200)
        handle_req2 = stub_request(:post, handles_url).
          with(body: hash_including({"source" => "email", "handle" => member.email})).
          to_return(status: 200)

        member.frontapp.upsert_contact
        expect(create_req).to have_been_made
        expect(member.frontapp_contact_id).to not_be_empty
        expect(update_req).to have_been_made
        expect(handle_req).to have_been_made
        expect(handle_req2).to have_been_made
      end
    end

    context "when the member contact id is present" do
      it "updates Front contact" do
        member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
        contact_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.frontapp.contact_id}").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
          )).to_return(status: 200)
        handles_url = "https://api2.frontapp.com/contacts/#{member.frontapp.contact_id}/handles"
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

      it "falls back to creating a contact if a NotFound error is raised" do
        member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_234")
        update_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.frontapp.contact_id}").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
          )).to_return(fixture_response("front/contact_not_found_error", status: 404))
        create_req = stub_request(:post, "https://api2.frontapp.com/contacts").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
            "handles" => [
              {"source" => "phone", "handle" => member.phone},
              {"source" => "email", "handle" => member.email},
            ],
          )).to_return(fixture_response("front/contact"))

        member.frontapp.upsert_contact
        expect(update_req).to have_been_made
        expect(create_req).to have_been_made
      end

      it "does not add Front contact handles if member is missing them" do
        member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
        member.email = nil
        member.phone = nil
        contact_req = stub_request(:patch, "https://api2.frontapp.com/contacts/#{member.frontapp.contact_id}").
          with(body: hash_including(
            "name" => member.name,
            "links" => [member.admin_link],
          )).to_return(status: 200)

        member.frontapp.upsert_contact
        expect(contact_req).to have_been_made
      end
    end
  end
end
