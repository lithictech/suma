# frozen_string_literal: true

require "suma/marketing"

RSpec.describe Suma::Marketing, :db do
  describe "dispatching a campaign" do
    let(:campaign) { Suma::Fixtures.marketing_sms_campaign.create }

    it "dispatches a campaign to members of a list" do
      list = Suma::Fixtures.marketing_list.create
      member = Suma::Fixtures.member.create
      list.add_member(member)
      expect(Suma::Async::MarketingSmsCampaignDispatch).to receive(:perform_async)
      campaign.dispatch(list)
      expect(campaign).to be_sent
      expect(campaign.sms_dispatches).to contain_exactly(
        have_attributes(member: be === member, sent_at: nil),
      )
    end

    it "does not duplicate members on multiple lists", :async do
      member1 = Suma::Fixtures.member.create
      member2 = Suma::Fixtures.member.create
      list1 = Suma::Fixtures.marketing_list.members(member1).create
      list2 = Suma::Fixtures.marketing_list.members(member1, member2).create
      campaign.sms_dispatches # Cache this to make sure we clear it after dispatch
      # Ensure we do an upsert on the dispatches, not just getting unique members.
      Suma::Fixtures.marketing_sms_dispatch.create(sms_campaign: campaign, member: member2)
      expect(Suma::Async::MarketingSmsCampaignDispatch).to receive(:perform_async)
      campaign.dispatch(list1, list2)
      expect(campaign.sms_dispatches).to contain_exactly(
        have_attributes(member: be === member1),
        have_attributes(member: be === member2),
      )
    end
  end

  describe "previewing a campaign" do
    it "can use a member" do
      c = Suma::Fixtures.marketing_sms_campaign.with_body("hello {{ name | default: 'there' }}", "hola {{name}}").create
      p = c.preview(Suma::Fixtures.member.create(name: "john"))
      expect(p[:en]).to eq("hello john")
      expect(p[:es]).to eq("hola john")
      p = c.preview(Suma::Fixtures.member.create(name: ""))
      expect(p[:en]).to eq("hello there")
      expect(p[:es]).to eq("hola ")
    end

    it "can use nil" do
      c = Suma::Fixtures.marketing_sms_campaign.with_body("hello {{ name | default: 'X' }}", "").create
      p = c.preview(nil)
      expect(p[:en]).to eq("hello X")
    end
  end

  describe "list specification" do
    it "includes only transport-enabled, undeleted members" do
      m = Suma::Fixtures.member.with_preferences.create
      disabled = Suma::Fixtures.member.with_preferences(sms_enabled: false).create
      deleted = Suma::Fixtures.member.with_preferences.create
      deleted.soft_delete
      es = Suma::Fixtures.member.with_preferences(preferred_language: "es").create

      spec = described_class::List::Specification.new(
        name: "mylist", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      expect(spec.members_dataset.all).to have_same_ids_as(m)
    end

    it "includes opted-in marketing lists" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      unsubscribed = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: unsubscribed, preferred_language: "en", marketing_sms_optout: true)

      specs = described_class::List::Specification.gather_all
      en = specs.find { |s| s.full_name == "Marketing - SMS - English" }
      es = specs.find { |s| s.full_name == "Marketing - SMS - Spanish" }
      expect(en.members_dataset.all).to have_same_ids_as(en_member)
      expect(es.members_dataset.all).to have_same_ids_as(es_member)
    end

    it "includes recently unverified members" do
      en_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: en_member, preferred_language: "en")

      es_member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: es_member, preferred_language: "es")

      verified = Suma::Fixtures.member.onboarding_verified.create
      Suma::Message::Preferences.create(member: verified)

      old = Suma::Fixtures.member.create(created_at: 2.months.ago)
      Suma::Message::Preferences.create(member: old)

      specs = described_class::List::Specification.gather_all
      en = specs.find { |s| s.full_name == "Unverified, last 30 days - SMS - English" }
      es = specs.find { |s| s.full_name == "Unverified, last 30 days - SMS - Spanish" }
      expect(en.members_dataset.all).to have_same_ids_as(en_member)
      expect(es.members_dataset.all).to have_same_ids_as(es_member)
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

      specs = described_class::List::Specification.gather_all
      o1_en_spec = specs.find { |s| s.full_name == "Org 1 - SMS - English" }
      o1_es_spec = specs.find { |s| s.full_name == "Org 1 - SMS - Spanish" }
      o2_en_spec = specs.find { |s| s.full_name == "Org 2 - SMS - English" }
      o2_es_spec = specs.find { |s| s.full_name == "Org 2 - SMS - Spanish" }
      expect(o1_en_spec.members_dataset.all).to have_same_ids_as(en_member)
      expect(o1_es_spec.members_dataset.all).to have_same_ids_as(es_member)
      expect(o2_en_spec.members_dataset.all).to have_same_ids_as(en_member)
      expect(o2_es_spec.members_dataset.all).to be_empty
    end
  end

  describe "list generation" do
    it "creates and adds members to the managed list" do
      member = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member:, preferred_language: "en")

      spec = described_class::List::Specification.new(
        name: "mylist", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      list = described_class::List.rebuild(spec)
      expect(list).to have_attributes(
        name: "mylist - SMS - English",
        managed: true,
      )
      expect(list.members).to contain_exactly(be === member)
    end

    it "deletes managed lists no longer in the specification" do
      spec1 = described_class::List::Specification.new(
        name: "mylist1", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      spec2 = described_class::List::Specification.new(
        name: "mylist2", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      spec3 = described_class::List::Specification.new(
        name: "mylist3", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )
      explicit_list = Suma::Fixtures.marketing_list.create(name: "customlist")
      lists = described_class::List.rebuild_all(spec1, spec2)
      expect(lists).to contain_exactly(
        have_attributes(name: "mylist1 - SMS - English"),
        have_attributes(name: "mylist2 - SMS - English"),
      )
      expect(described_class::List.all).to contain_exactly(
        have_attributes(name: "mylist1 - SMS - English"),
        have_attributes(name: "mylist2 - SMS - English"),
        have_attributes(name: "customlist"),
      )

      lists = described_class::List.rebuild_all(spec3, spec2)
      expect(lists).to contain_exactly(
        have_attributes(name: "mylist3 - SMS - English"),
        have_attributes(name: "mylist2 - SMS - English"),
      )
      expect(described_class::List.all).to contain_exactly(
        have_attributes(name: "mylist3 - SMS - English"),
        have_attributes(name: "mylist2 - SMS - English"),
        have_attributes(name: "customlist"),
      )
    end

    it "replaces list members on update" do
      spec = described_class::List::Specification.new(
        name: "mylist", transport: :sms, members_dataset: Suma::Member.dataset, language: "en",
      )

      member1 = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: member1, preferred_language: "en")
      member2 = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: member2, preferred_language: "en")

      list = described_class::List.rebuild(spec)
      expect(list.members).to contain_exactly(be === member1, be === member2)

      member3 = Suma::Fixtures.member.create
      Suma::Message::Preferences.create(member: member3, preferred_language: "en")
      member2.soft_delete

      list = described_class::List.rebuild(spec)
      expect(list.members).to contain_exactly(be === member1, be === member3)
    end
  end

  describe "sending dispatches", :no_transaction_check, reset_configuration: Suma::Signalwire do
    before(:each) do
      Suma::Signalwire.marketing_number = "12223334444"
    end

    it "sends the SMS through Signalwire using the member's preferred language" do
      en = Suma::Fixtures.member.with_preferences(preferred_language: "en").create(phone: "15556667777", name: "Eng")
      es = Suma::Fixtures.member.with_preferences(preferred_language: "es").create(phone: "15556669999", name: "Esp")
      sms_campaign = Suma::Fixtures.marketing_sms_campaign.with_body("hi {{name}}", "hola {{name}}").create

      d_en = Suma::Fixtures.marketing_sms_dispatch.create(sms_campaign:, member: en)
      d_es = Suma::Fixtures.marketing_sms_dispatch.create(sms_campaign:, member: es)
      # this is already sent so will be skipped
      d_sent = Suma::Fixtures.marketing_sms_dispatch.sent.create
      req_en = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json").
        with(body: {"Body" => "hi Eng", "From" => "+12223334444", "To" => "+15556667777"}).
        to_return(json_response(load_fixture_data("signalwire/send_message")))
      req_es = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json").
        with(body: {"Body" => "hola Esp", "From" => "+12223334444", "To" => "+15556669999"}).
        to_return(json_response(load_fixture_data("signalwire/send_message")))

      described_class::SmsDispatch.send_all
      expect(req_en).to have_been_made
      expect(req_es).to have_been_made

      expect(d_en.refresh).to have_attributes(
        sent?: true,
        transport_message_id: "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      )
      expect(d_es.refresh).to have_attributes(
        sent?: true,
        transport_message_id: "SMXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
      )
    end

    it "noops if the marketing number is not set" do
      Suma::Signalwire.marketing_number = ""
      Suma::Fixtures.marketing_sms_dispatch.create
      expect { described_class::SmsDispatch.send_all }.to_not raise_error
    end

    it "handles errors by sending them to Sentry and moving on" do
      disp = Suma::Fixtures.marketing_sms_dispatch.create
      req = stub_request(:post, "https://sumafaketest.signalwire.com/2010-04-01/Accounts/sw-test-project/Messages.json").
        to_return(
          json_response(load_fixture_data("signalwire/error_internal").merge("code" => "123"), status: 400),
        )
      expect(Sentry).to receive(:capture_exception).with(any_args) do |e|
        expect(e).to be_a(Twilio::REST::RestError)
        expect(e.to_s).to include("Unable to create record")
      end

      described_class::SmsDispatch.send_all
      expect(req).to have_been_made

      expect(disp.refresh).to have_attributes(
        sent?: false,
        transport_message_id: nil,
      )
    end
  end

  describe "Suma::Marketing::SmsCampaign" do
    it "can add and remove lists" do
      c = Suma::Fixtures.marketing_sms_campaign.create
      expect(c.lists).to be_empty
      l1 = Suma::Fixtures.marketing_list.create
      c.add_list(l1)
      expect(c.lists).to contain_exactly(l1)
    end
  end
end
