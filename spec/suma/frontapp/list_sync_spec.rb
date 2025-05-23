# frozen_string_literal: true

require "suma/frontapp/list_sync"

RSpec.describe Suma::Frontapp::ListSync, :db, reset_configuration: Suma::Frontapp do
  let(:now) { Time.now }

  before(:each) do
    Suma::Frontapp.auth_token = "abc"
    Suma::Frontapp.list_sync_enabled = true
  end

  describe "syncing lists" do
    it "creates the specified lists in Front" do
      m = Suma::Fixtures.member.onboarding_verified.create
      m.preferences!

      get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
        to_return(
          json_response({}),
          json_response(
            {
              _results: [
                {id: "grp_en", name: "Marketing - SMS - English"},
                {id: "grp_es", name: "Marketing - SMS - Spanish"},
              ],
            },
          ),
        )
      create_en_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
        with(body: "{\"name\":\"Marketing - SMS - English\"}").
        to_return(json_response({}))
      add_ids = stub_request(:post, "https://api2.frontapp.com/contact_groups/grp_en/contacts").
        with(body: "{\"contact_ids\":[\"alt:phone:#{m.phone}\"]}").
        to_return(json_response({}))

      described_class.new(now:).run

      expect(get_groups).to have_been_made.times(2)
      expect(create_en_group).to have_been_made
      expect(add_ids).to have_been_made
    end

    it "first deletes lists with the same name" do
      m = Suma::Fixtures.member.onboarding_verified.create
      m.preferences!

      get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
        to_return(
          json_response(
            {
              _results: [
                {id: "grp_en1", name: "Marketing - SMS - English"},
              ],
            },
          ),
          json_response(
            {
              _results: [
                {id: "grp_en2", name: "Marketing - SMS - English"},
              ],
            },
          ),
        )
      delete_en = stub_request(:delete, "https://api2.frontapp.com/contact_groups/grp_en1").
        with(body: "{}").
        to_return(json_response({}))

      create_en_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
        with(body: "{\"name\":\"Marketing - SMS - English\"}").
        to_return(json_response({}))
      add_ids = stub_request(:post, "https://api2.frontapp.com/contact_groups/grp_en2/contacts").
        with(body: "{\"contact_ids\":[\"alt:phone:#{m.phone}\"]}").
        to_return(json_response({}))

      described_class.new(now:).run

      expect(get_groups).to have_been_made.times(2)
      expect(delete_en).to have_been_made
      expect(create_en_group).to have_been_made
      expect(add_ids).to have_been_made
    end

    it "does not create empty lists" do
      get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
        to_return(
          json_response({}),
          json_response({}),
        )
      described_class.new(now:).run

      expect(get_groups).to have_been_made.times(2)
    end

    it "deletes lists that exist but are now empty" do
      get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
        to_return(
          json_response(
            {
              _results: [
                {id: "grp_en1", name: "Marketing - SMS - English"},
              ],
            },
          ),
          json_response({}),
        )
      delete_en = stub_request(:delete, "https://api2.frontapp.com/contact_groups/grp_en1").
        with(body: "{}").
        to_return(json_response({}))

      described_class.new(now:).run

      expect(get_groups).to have_been_made.times(2)
      expect(delete_en).to have_been_made
    end

    it "does not modify groups that cannot be recognized" do
      get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
        to_return(
          json_response(
            {
              _results: [
                {id: "some group", name: "Custom made"},
              ],
            },
          ),
          json_response({}),
        )
      described_class.new(now:).run

      expect(get_groups).to have_been_made.times(2)
    end

    describe "when a contact is missing" do
      def create_member
        m = Suma::Fixtures.member.onboarding_verified.create
        m.preferences!
        return m
      end

      it "upserts them and retries" do
        m_fail1 = create_member
        m_succeed = create_member
        m_fail2 = create_member

        get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
          to_return(
            json_response({}),
            json_response({_results: [{id: "grp_en", name: "Marketing - SMS - English"}]}),
          )
        create_en_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
          with(body: "{\"name\":\"Marketing - SMS - English\"}").
          to_return(json_response({}))
        add_ids = stub_request(:post, "https://api2.frontapp.com/contact_groups/grp_en/contacts").
          with(body: {
                 contact_ids: [
                   "alt:phone:#{m_fail1.phone}",
                   "alt:phone:#{m_succeed.phone}",
                   "alt:phone:#{m_fail2.phone}",
                 ],
               }).
          to_return(
            json_response(
              {_error: {status: 404, title: "Not found", message: "Unknown contact ID alt:phone:#{m_fail1.phone}"}},
              status: 404,
            ),
            json_response(
              {_error: {status: 404, title: "Not found", message: "Unknown contact ID alt:phone:#{m_fail2.phone}"}},
              status: 404,
            ),
            json_response({}),
          )
        create_missing1 = stub_request(:post, "https://api2.frontapp.com/contacts").
          with(body: hash_including("name" => m_fail1.name)).
          to_return(fixture_response("front/contact"))
        create_missing2 = stub_request(:post, "https://api2.frontapp.com/contacts").
          with(body: hash_including("name" => m_fail2.name)).
          to_return(fixture_response("front/contact"))

        described_class.new(now:).run

        expect(get_groups).to have_been_made.times(2)
        expect(create_en_group).to have_been_made
        expect(add_ids).to have_been_made.times(3)
        expect(create_missing1).to have_been_made
        expect(create_missing2).to have_been_made
      end

      it "fails if the next call adds with the same account" do
        m_fail1 = create_member

        get_groups = stub_request(:get, "https://api2.frontapp.com/contact_groups").
          to_return(
            json_response({}),
            json_response({_results: [{id: "grp_en", name: "Marketing - SMS - English"}]}),
          )
        create_en_group = stub_request(:post, "https://api2.frontapp.com/contact_groups").
          with(body: "{\"name\":\"Marketing - SMS - English\"}").
          to_return(json_response({}))
        add_ids = stub_request(:post, "https://api2.frontapp.com/contact_groups/grp_en/contacts").
          with(body: {contact_ids: ["alt:phone:#{m_fail1.phone}"]}).
          to_return(
            json_response(
              {_error: {status: 404, title: "Not found", message: "Unknown contact ID alt:phone:#{m_fail1.phone}"}},
              status: 404,
            ),
            json_response(
              {_error: {status: 404, title: "Not found", message: "Unknown contact ID alt:phone:#{m_fail1.phone}"}},
              status: 404,
            ),
          )
        create_missing1 = stub_request(:post, "https://api2.frontapp.com/contacts").
          with(body: hash_including("name" => m_fail1.name)).
          to_return(fixture_response("front/contact"))

        expect { described_class.new(now:).run }.to raise_error(Frontapp::NotFoundError)

        expect(get_groups).to have_been_made.times(2)
        expect(create_en_group).to have_been_made
        expect(add_ids).to have_been_made.times(2)
        expect(create_missing1).to have_been_made
      end
    end
  end

  describe "ListSpec" do
    it "dataset include only transport-enabled, undeleted members" do
      m = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: m)

      disabled = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: disabled, sms_enabled: false)

      deleted = Suma::Fixtures.member.create
      deleted.soft_delete
      Suma::Message::Preferences.create(member: deleted)

      es = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es, preferred_language: "es")

      spec = described_class::ListSpec.new(
        name: "myspec", transport: :sms, dataset: Suma::Member.dataset, language: "en",
      )
      expect(spec.dataset.all).to have_same_ids_as(m)
    end
  end

  describe "list segmentation" do
    it "includes opted-in marketing lists" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      unsubscribed = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: unsubscribed, preferred_language: "en", marketing_sms_optout: true)

      specs = described_class.new(now:).gather_list_specs
      en = specs.find { |s| s.full_name == "Marketing - SMS - English" }
      es = specs.find { |s| s.full_name == "Marketing - SMS - Spanish" }
      expect(en.dataset.all).to have_same_ids_as(en_member)
      expect(es.dataset.all).to have_same_ids_as(es_member)
    end

    it "includes recently unverified users" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      verified = Suma::Fixtures.member.onboarding_verified.create
      Suma::Message::Preferences.create(member: verified)

      old = Suma::Fixtures.member.create(created_at: 2.months.ago)
      Suma::Message::Preferences.create(member: old)

      specs = described_class.new(now:).gather_list_specs
      en = specs.find { |s| s.full_name == "Unverified, last 30 days - SMS - English" }
      es = specs.find { |s| s.full_name == "Unverified, last 30 days - SMS - Spanish" }
      expect(en.dataset.all).to have_same_ids_as(en_member)
      expect(es.dataset.all).to have_same_ids_as(es_member)
    end

    it "includes per-organization list" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      o1 = Suma::Fixtures.organization.create(name: "Org 1")
      o2 = Suma::Fixtures.organization.create(name: "Org 2")
      Suma::Fixtures.organization_membership.verified(o1).create(member: en_member)
      Suma::Fixtures.organization_membership.verified(o2).create(member: en_member)
      Suma::Fixtures.organization_membership.verified(o1).create(member: es_member)

      specs = described_class.new(now:).gather_list_specs
      o1_en_spec = specs.find { |s| s.full_name == "Org 1 - SMS - English" }
      o1_es_spec = specs.find { |s| s.full_name == "Org 1 - SMS - Spanish" }
      o2_en_spec = specs.find { |s| s.full_name == "Org 2 - SMS - English" }
      o2_es_spec = specs.find { |s| s.full_name == "Org 2 - SMS - Spanish" }
      expect(o1_en_spec.dataset.all).to have_same_ids_as(en_member)
      expect(o1_es_spec.dataset.all).to have_same_ids_as(es_member)
      expect(o2_en_spec.dataset.all).to have_same_ids_as(en_member)
      expect(o2_es_spec.dataset.all).to be_empty
    end
  end
end
