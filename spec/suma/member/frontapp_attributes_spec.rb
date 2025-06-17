# frozen_string_literal: true

RSpec.describe Suma::Member::FrontappAttributes, :db do
  let(:member) { Suma::Fixtures.member.create(email: "x@y.z", phone: "15552223333", name: "R G") }

  describe "upsert front contacts" do
    it "creates a contact" do
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
      expect(contact_req).to have_been_made
    end

    describe "when there is a conflict with an existing email and phone" do
      describe "and they both point to the same contact" do
        it "updates the contact and adds the handles" do
          create = stub_request(:post, "https://api2.frontapp.com/contacts").
            to_return(fixture_response("front/contact_conflict_error", status: 409))
          get_email = stub_request(:get, "https://api2.frontapp.com/contacts/alt:email:x@y.z").
            to_return(fixture_response("front/contact"))
          get_phone = stub_request(:get, "https://api2.frontapp.com/contacts/alt:phone:15552223333").
            to_return(fixture_response("front/contact"))
          update = stub_request(:patch, "https://api2.frontapp.com/contacts/crd_123").
            with(body: {
              name: "R G",
              links: ["http://localhost:22014/member/#{member.id}"],
              custom_fields: {"SMS Marketing Opted Out": false, Language: "English"},
            }.to_json).
            to_return(fixture_response("front/contact"))
          phonehandle = stub_request(:post, "https://api2.frontapp.com/contacts/crd_123/handles").
            with(body: "{\"handle\":\"15552223333\",\"source\":\"phone\"}").
            to_return(fixture_response("front/contact"))
          emailhandle = stub_request(:post, "https://api2.frontapp.com/contacts/crd_123/handles").
            with(body: "{\"handle\":\"x@y.z\",\"source\":\"email\"}").
            to_return(fixture_response("front/contact"))

          member.frontapp.upsert_contact

          expect(create).to have_been_made
          expect(get_email).to have_been_made
          expect(get_phone).to have_been_made
          expect(update).to have_been_made
          expect(phonehandle).to have_been_made
          expect(emailhandle).to have_been_made
        end
      end

      describe "and they point to different contacts" do
        it "merges the contacts and then updates the merged contact" do
          create = stub_request(:post, "https://api2.frontapp.com/contacts").
            to_return(fixture_response("front/contact_conflict_error", status: 409))
          get_email = stub_request(:get, "https://api2.frontapp.com/contacts/alt:email:x@y.z").
            to_return(fixture_response("front/contact"))
          get_phone = stub_request(:get, "https://api2.frontapp.com/contacts/alt:phone:15552223333").
            to_return(
              fixture_response(body: load_fixture_data("front/contact").merge("id" => "othercontactid").to_json),
            )
          merge = stub_request(:post, "https://api2.frontapp.com/contacts/merge").
            with(body: "{\"contact_ids\":[\"othercontactid\",\"crd_123\"]}").
            to_return(
              fixture_response(body: load_fixture_data("front/contact").merge("id" => "mergedid").to_json),
            )
          # Make sure we use the merged contact id for future ops
          update = stub_request(:patch, "https://api2.frontapp.com/contacts/mergedid").
            with(body: {
              name: "R G",
              links: ["http://localhost:22014/member/#{member.id}"],
              custom_fields: {"SMS Marketing Opted Out": false, Language: "English"},
            }.to_json).
            to_return(fixture_response("front/contact"))
          phonehandle = stub_request(:post, "https://api2.frontapp.com/contacts/mergedid/handles").
            with(body: "{\"handle\":\"15552223333\",\"source\":\"phone\"}").
            to_return(fixture_response("front/contact"))
          emailhandle = stub_request(:post, "https://api2.frontapp.com/contacts/mergedid/handles").
            with(body: "{\"handle\":\"x@y.z\",\"source\":\"email\"}").
            to_return(fixture_response("front/contact"))

          member.frontapp.upsert_contact

          expect(create).to have_been_made
          expect(get_email).to have_been_made
          expect(get_phone).to have_been_made
          expect(merge).to have_been_made
          expect(update).to have_been_made
          expect(phonehandle).to have_been_made
          expect(emailhandle).to have_been_made
        end
      end
    end

    describe "when there is a conflict with a single handle" do
      it "updates the contact and adds the handles" do
        create = stub_request(:post, "https://api2.frontapp.com/contacts").
          to_return(fixture_response("front/contact_conflict_error", status: 409))
        get_email = stub_request(:get, "https://api2.frontapp.com/contacts/alt:email:x@y.z").
          to_return(fixture_response("front/contact"))
        get_phone = stub_request(:get, "https://api2.frontapp.com/contacts/alt:phone:15552223333").
          to_return(fixture_response("front/contact_not_found_error", status: 404))

        update = stub_request(:patch, "https://api2.frontapp.com/contacts/crd_123").
          to_return(fixture_response("front/contact"))
        phonehandle = stub_request(:post, "https://api2.frontapp.com/contacts/crd_123/handles").
          with(body: "{\"handle\":\"15552223333\",\"source\":\"phone\"}").
          to_return(fixture_response("front/contact"))
        emailhandle = stub_request(:post, "https://api2.frontapp.com/contacts/crd_123/handles").
          with(body: "{\"handle\":\"x@y.z\",\"source\":\"email\"}").
          to_return(fixture_response("front/contact"))

        member.frontapp.upsert_contact

        expect(create).to have_been_made
        expect(get_email).to have_been_made
        expect(get_phone).to have_been_made
        expect(update).to have_been_made
        expect(phonehandle).to have_been_made
        expect(emailhandle).to have_been_made
      end

      it "only adds non-blank handles" do
        member.update(email: nil)
        create = stub_request(:post, "https://api2.frontapp.com/contacts").
          to_return(fixture_response("front/contact_conflict_error", status: 409))
        get_phone = stub_request(:get, "https://api2.frontapp.com/contacts/alt:phone:15552223333").
          to_return(fixture_response("front/contact"))

        update = stub_request(:patch, "https://api2.frontapp.com/contacts/crd_123").
          to_return(fixture_response("front/contact"))
        phonehandle = stub_request(:post, "https://api2.frontapp.com/contacts/crd_123/handles").
          with(body: "{\"handle\":\"15552223333\",\"source\":\"phone\"}").
          to_return(fixture_response("front/contact"))

        member.frontapp.upsert_contact

        expect(create).to have_been_made
        expect(get_phone).to have_been_made
        expect(update).to have_been_made
        expect(phonehandle).to have_been_made
      end
    end
  end
end
