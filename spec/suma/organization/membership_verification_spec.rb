# frozen_string_literal: true

RSpec.describe "Suma::Organization::MembershipVerification", :db do
  let(:described_class) { Suma::Organization::MembershipVerification }

  it "can fixture itself" do
    expect { Suma::Fixtures.organization_membership_verification.create }.to_not raise_error
  end

  it "has relations" do
    v = Suma::Fixtures.organization_membership_verification.create
    expect(v.membership.verification).to be === v
    expect(v.audit_logs).to be_empty
  end

  it "can find webhookdb associations" do
    v = Suma::Fixtures.organization_membership_verification.create
    expect(v.front_partner_conversation).to be_nil
    expect(v.front_member_conversation).to be_nil
    expect(v.front_latest_partner_message).to be_nil
    expect(v.front_latest_member_message).to be_nil
    convo1 = Suma::Webhookdb::FrontConversation.create(front_id: "convo1", data: "{}")
    convo2 = Suma::Webhookdb::FrontConversation.create(front_id: "convo2", data: "{}")
    msg1 = Suma::Webhookdb::FrontMessage.create(
      front_id: "msg1", front_conversation_id: "convo1", created_at: 3.hours.ago, data: "{}",
    )
    msg2 = Suma::Webhookdb::FrontMessage.create(
      front_id: "msg2", front_conversation_id: "convo1", created_at: 2.hours.ago, data: "{}",
    )
    msg3 = Suma::Webhookdb::FrontMessage.create(
      front_id: "msg3", front_conversation_id: "convo2", created_at: 1.hours.ago, data: "{}",
    )
    v.refresh
    v.update(partner_outreach_front_conversation_id: "convo1", member_outreach_front_conversation_id: "convo2")
    expect(v.front_partner_conversation).to be === convo1
    expect(v.front_member_conversation).to be === convo2
    expect(v.front_latest_partner_message).to be === msg2
    expect(v.front_latest_member_message).to be === msg3
  end

  describe "state machines" do
    it "can perform simple transitions" do
      v = Suma::Fixtures.organization_membership_verification.create
      expect(v).to transition_on(:start).to("in_progress")
      expect(v).to transition_on(:abandon).to("abandoned")
      expect(v).to transition_on(:resume).to("in_progress")
      v.status = "in_progress"
      expect(v).to transition_on(:reject).to("ineligible")
      v.status = "in_progress"
      expect(v).to transition_on(:approve).to("verified")
    end

    it "knows available events for the current state" do
      v = Suma::Fixtures.organization_membership_verification.create
      expect(v.state_machine.available_events).to eq([:start])
      v.status = :in_progress
      expect(v.state_machine.available_events).to eq([:abandon, :reject, :approve])
    end
  end

  describe "begin_partner_outreach", reset_configuration: described_class do
    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    before(:each) do
      described_class.front_partner_channel_id = "cha123"
    end

    it "calls Front and saves the response" do
      v.membership.member.update(name: "Patricia Monahan", phone: "12158631080")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: {
            subject: "Verification request for Patricia Monahan",
            body: "Verification information for Patricia Monahan\n\nPhone: (215) 863-1080",
            mode: "shared",
            should_add_default_signature: true,
          }.to_json,
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      v.begin_partner_outreach
      expect(req).to have_been_made
      expect(v.refresh).to have_attributes(
        partner_outreach_front_conversation_id: "cnv_yo1kg5q",
      )
    end

    it "uses the current admin as the author" do
      admin = Suma::Fixtures.member.create(phone: "19512371020")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: hash_including("author_id" => "alt:phone:+19512371020"),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      Suma.set_request_user_and_admin(nil, admin) do
        v.begin_partner_outreach
      end
      expect(req).to have_been_made
    end

    it "includes maximum available information" do
      address = Suma::Fixtures.address.create
      v.membership.member.legal_entity.update(address:)
      v.membership.member.update(email: "z@mysuma.org")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: hash_including("body" => include("Address: ")),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      v.begin_partner_outreach
      expect(req).to have_been_made
    end

    it "emails the organization membership verification email if set" do
      o = Suma::Fixtures.organization.create(membership_verification_email: "office@mysuma.org")
      v.membership.unverified_organization_name = o.name
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: hash_including("to" => ["alt:email:office@mysuma.org"]),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      v.begin_partner_outreach
      expect(req).to have_been_made
    end
  end

  describe "begin_member_outreach", reset_configuration: described_class do
    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    before(:each) do
      described_class.front_member_channel_id = "cha456"
    end

    it "calls Front and saves the response" do
      v.membership.member.update(name: "Patricia Monahan", phone: "12158631080")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha456/drafts").
        with(
          body: {
            body: "TK",
            mode: "shared",
            should_add_default_signature: false,
          }.to_json,
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      v.begin_member_outreach
      expect(req).to have_been_made
      expect(v.refresh).to have_attributes(
        member_outreach_front_conversation_id: "cnv_yo1kg5q",
      )
    end

    it "uses the current admin as the author" do
      admin = Suma::Fixtures.member.create(phone: "19512371020")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha456/drafts").
        with(
          body: hash_including("author_id" => "alt:phone:+19512371020"),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      Suma.set_request_user_and_admin(nil, admin) do
        v.begin_member_outreach
      end
      expect(req).to have_been_made
    end
  end

  describe "front messages" do
    let(:v) do
      Suma::Fixtures.organization_membership_verification.create(
        partner_outreach_front_conversation_id: "cnv_partner",
        member_outreach_front_conversation_id: "cnv_member",
      )
    end

    it "finds nothing if there are no Front ids set" do
      v.update(partner_outreach_front_conversation_id: nil, member_outreach_front_conversation_id: nil)
      expect(v).to have_attributes(
        front_partner_conversation_status: nil,
        front_member_conversation_status: nil,
      )
    end

    it "uses the conversation if there is not Front message for the conversation" do
      expect(v).to have_attributes(
        front_partner_conversation_status: have_attributes(
          last_updated_at: nil,
          waiting_on_admin: false,
          waiting_on_member: true,
          web_url: "https://app.frontapp.com/open/cnv_partner",
        ),
        front_member_conversation_status: have_attributes(
          web_url: "https://app.frontapp.com/open/cnv_member",
        ),
      )
    end

    it "uses the message if there is a Front message in webhookdb" do
      t1 = 2.hour.ago
      t2 = 1.hour.ago
      Suma::Webhookdb::FrontMessage.create(
        front_id: "msg1", front_conversation_id: "cnv_partner", created_at: t1, data: "{}",
      )
      expect(v).to have_attributes(
        front_partner_conversation_status: have_attributes(
          last_updated_at: match_time(t1),
          waiting_on_admin: false,
          waiting_on_member: true,
          web_url: "https://app.frontapp.com/open/msg1",
        ),
      )
      Suma::Webhookdb::FrontMessage.create(
        front_id: "msg2", front_conversation_id: "cnv_partner", created_at: t2, data: {is_inbound: true},
      )
      expect(v.refresh).to have_attributes(
        front_partner_conversation_status: have_attributes(
          last_updated_at: match_time(t2),
          waiting_on_admin: true,
          waiting_on_member: false,
          web_url: "https://app.frontapp.com/open/msg2",
        ),
      )
    end
  end
end
