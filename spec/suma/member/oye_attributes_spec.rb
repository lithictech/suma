# frozen_string_literal: true

RSpec.describe Suma::Member::OyeAttributes, :db do
  let(:member) { Suma::Fixtures.member.create }

  describe "sync oye sms status" do
    it "updates status if member contains contact id" do
      member = Suma::Fixtures.member.create(oye_contact_id: "1")
      status_update_req = stub_request(:put, "https://app.oyetext.org/api/v1/contacts/bulk_update").
        to_return(fixture_response("oye/bulk_update_contacts"), status: 200)

      member.oye.upsert_sms_status
      expect(status_update_req).to have_been_made
    end

    it "sets contact id on member if it is blank" do
      member.update(phone: "12223334444")
      get_contacts_req = stub_request(:get, "https://app.oyetext.org/api/v1/contacts").
        to_return(fixture_response("oye/contacts_get"), status: 200)
      status_update_req = stub_request(:put, "https://app.oyetext.org/api/v1/contacts/bulk_update").
        to_return(fixture_response("oye/bulk_update_contacts"), status: 200)

      member.oye.upsert_sms_status
      expect(get_contacts_req).to have_been_made
      expect(status_update_req).to have_been_made
      expect(member).to have_attributes(oye_contact_id: "1")
    end
  end
end
