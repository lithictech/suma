# frozen_string_literal: true

require "suma/frontapp/list_sync"

RSpec.describe Suma::Frontapp::ListSync, :db, reset_configuration: Suma::Frontapp do
  let(:now) { Time.now }

  before(:each) do
    Suma::Frontapp.auth_token = "abc"
    Suma::Frontapp.list_sync_enabled = true
  end

  it "creates the specified lists in Front" do
    get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
      to_return(
        json_response({}),
        json_response(
          {
            _results: [
              {id: "grp_en", name: "SMS Marketing (English)"},
              {id: "grp_es", name: "SMS Marketing (Spanish)"},
            ],
          },
        ),
      )
    create_en_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
      with(body: "{\"name\":\"SMS Marketing (English)\"}").
      to_return(json_response({}))
    create_es_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
      with(body: "{\"name\":\"SMS Marketing (Spanish)\"}").
      to_return(json_response({}))
    add_ids = stub_request(:post, "https://api2.frontapp.com/contact_groups/grp_en/contacts").
      with(body: "{\"contact_ids\":[\"crd_123\"]}").
      to_return(json_response({}))

    m = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
    m.preferences!

    described_class.new(now:).run

    expect(get_groups).to have_been_made.times(2)
    expect(create_en_group).to have_been_made
    expect(create_es_group).to have_been_made
    expect(add_ids).to have_been_made
  end

  it "first deletes lists with the same name" do
    get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
      to_return(
        json_response(
          {
            _results: [
              {id: "grp_en1", name: "SMS Marketing (English)"},
            ],
          },
        ),
        json_response(
          {
            _results: [
              {id: "grp_en2", name: "SMS Marketing (English)"},
              {id: "grp_es", name: "SMS Marketing (Spanish)"},
            ],
          },
        ),
      )
    delete_en = stub_request(:delete, "https://api2.frontapp.com/contact_groups/grp_en1").
      with(body: "{}").
      to_return(json_response({}))

    create_en_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
      with(body: "{\"name\":\"SMS Marketing (English)\"}").
      to_return(json_response({}))
    create_es_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
      with(body: "{\"name\":\"SMS Marketing (Spanish)\"}").
      to_return(json_response({}))
    add_ids = stub_request(:post, "https://api2.frontapp.com/contact_groups/grp_en2/contacts").
      with(body: "{\"contact_ids\":[\"crd_123\"]}").
      to_return(json_response({}))

    m = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
    m.preferences!

    described_class.new(now:).run

    expect(get_groups).to have_been_made.times(2)
    expect(delete_en).to have_been_made
    expect(create_en_group).to have_been_made
    expect(create_es_group).to have_been_made
    expect(add_ids).to have_been_made
  end

  describe "SMS marketing lists" do
    it "includes opted in members with a given language" do
      en_member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      unsubscribed_en_member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
      Suma::Message::Preferences.
        create(member: unsubscribed_en_member, preferred_language: "en", marketing_sms_optout: true)

      unsubscribed_es_member = Suma::Fixtures.member.create(frontapp_contact_id: "crd_123")
      Suma::Message::Preferences.
        create(member: unsubscribed_es_member, preferred_language: "es", marketing_sms_optout: true)

      no_front_id = Suma::Fixtures.member.create(frontapp_contact_id: "")
      Suma::Message::Preferences.create(member: no_front_id)

      specs = described_class.new(now:).gather_list_specs
      en = specs.find { |s| s.name == "SMS Marketing (English)" }
      es = specs.find { |s| s.name == "SMS Marketing (Spanish)" }
      expect(en.dataset.all).to have_same_ids_as(en_member)
      expect(es.dataset.all).to have_same_ids_as(es_member)
    end
  end
end
