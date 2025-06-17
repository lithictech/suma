# frozen_string_literal: true

RSpec.describe "Suma::Organization::Membership::Verification",
               :db,
               reset_configuration: Suma::Organization::Membership::Verification do
  let(:described_class) { Suma::Organization::Membership::Verification }

  describe "configuration" do
    it "converts numeric IDs to API ids" do
      described_class.front_partner_channel_id = "12345"
      described_class.front_member_channel_id = "cha_12345"
      described_class.front_partner_default_template_id = "12345"
      described_class.front_member_default_en_template_id = "rsp_12345"
      described_class.front_member_default_es_template_id = "rsp_555"
      described_class.run_after_configured_hooks
      expect(described_class.front_partner_channel_id).to eq("cha_9ix")
      expect(described_class.front_member_channel_id).to eq("cha_12345")
      expect(described_class.front_partner_default_template_id).to eq("rsp_9ix")
      expect(described_class.front_member_default_en_template_id).to eq("rsp_12345")
      expect(described_class.front_member_default_es_template_id).to eq("rsp_555")
    end
  end

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
      v = Suma::Fixtures.organization_membership_verification.able_to_verify.create
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
      expect(v.state_machine.available_events).to eq([:abandon, :reject])
    end

    describe "start" do
      let(:v) { Suma::Fixtures.organization_membership_verification.create }

      it "sets the owner to the current admin" do
        v.update(owner: Suma::Fixtures.member.create) # Replace whatever is there
        admin = Suma::Fixtures.member.create(email: "paula_pagac@ebert.test")
        Suma.set_request_user_and_admin(nil, admin) do
          expect(v).to transition_on(:start).to("in_progress")
        end
        expect(v.owner).to be === admin
      end

      it "does not set the owner if there is no current admin" do
        owner = Suma::Fixtures.member.create
        v.update(owner:)
        expect(v).to transition_on(:start).to("in_progress")
        expect(v.owner).to be === owner
      end
    end

    describe "approve" do
      it "sets the matching organization verified" do
        org = Suma::Fixtures.organization.create
        membership = Suma::Fixtures.organization_membership.unverified(org.name).create
        v = Suma::Fixtures.organization_membership_verification.create(membership:, status: "in_progress")
        expect(v).to transition_on(:approve).to("verified")
        expect(membership).to be_verified
      end

      it "fails if there is no org matching the unverified org name" do
        membership = Suma::Fixtures.organization_membership.unverified.create
        v = Suma::Fixtures.organization_membership_verification.create(membership:, status: "in_progress")
        expect(v).to not_transition_on(:approve)
      end

      it "succeeds if the membership is already verified" do
        membership = Suma::Fixtures.organization_membership.verified.create
        v = Suma::Fixtures.organization_membership_verification.create(membership:, status: "in_progress")
        expect(v).to transition_on(:approve).to("verified")
      end

      it "fails if the membership is former" do
        membership = Suma::Fixtures.organization_membership.former.create
        v = Suma::Fixtures.organization_membership_verification.create(membership:, status: "in_progress")
        expect(v).to not_transition_on(:approve)
      end
    end
  end

  describe "begin_partner_outreach" do
    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    before(:each) do
      described_class.front_partner_channel_id = "cha123"
    end

    it "calls Front and saves the response" do
      v.membership.member.update(name: "Patricia Monahan", phone: "12158631080")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: hash_including(
            "subject" => "Verification request for Patricia Monahan",
            "body" => include("Phone: (215) 863-1080"),
            "mode" => "shared",
            "should_add_default_signature" => true,
          ),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      v.begin_partner_outreach
      expect(req).to have_been_made
      expect(v.refresh).to have_attributes(
        partner_outreach_front_conversation_id: "cnv_yo1kg5q",
      )
    end

    it "uses the current admin as the author if there is a teammate with matching email" do
      admin = Suma::Fixtures.member.create(email: "paula_pagac@ebert.test")
      teammate_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:email:paula_pagac@ebert.test").
        to_return(json_response(load_fixture_data("front/teammate")))

      draft_req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: hash_including("author_id" => "tea_6r55a"),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      Suma.set_request_user_and_admin(nil, admin) do
        v.begin_partner_outreach
      end
      expect(teammate_req).to have_been_made
      expect(draft_req).to have_been_made
    end

    it "uses the current admin as the author if there is a teammate with matching phone" do
      admin = Suma::Fixtures.member.create(phone: "19512371020", email: nil)
      teammate_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:phone:+19512371020").
        to_return(json_response(load_fixture_data("front/teammate")))
      draft_req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        with(
          body: hash_including("author_id" => "tea_6r55a"),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      Suma.set_request_user_and_admin(nil, admin) do
        v.begin_partner_outreach
      end
      expect(teammate_req).to have_been_made
      expect(draft_req).to have_been_made
    end

    it "does not set an author if no matching teammate can be found" do
      admin = Suma::Fixtures.member.create(phone: "19512371020", email: "paula_pagac@ebert.test")
      teammate_phone_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:phone:+19512371020").
        to_return(status: 404)
      teammate_email_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:email:paula_pagac@ebert.test").
        to_return(status: 404)
      draft_req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
        to_return(json_response(load_fixture_data("front/channel_create_draft")))
      Suma.set_request_user_and_admin(nil, admin) do
        v.begin_partner_outreach
      end
      expect(teammate_phone_req).to have_been_made
      expect(teammate_email_req).to have_been_made
      expect(draft_req).to have_been_made
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
          body: hash_including("to" => ["office@mysuma.org"]),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      v.begin_partner_outreach
      expect(req).to have_been_made
    end

    describe "template usage" do
      before(:each) do
        described_class.front_partner_default_template_id = "rsp_default"
      end

      it "uses the default partner template text if set" do
        tmpl_req = stub_request(:get, "https://api2.frontapp.com/message_templates/rsp_default").
          to_return(json_response(load_fixture_data("front/message_template")))

        req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
          with(
            body: hash_including(
              "subject" => "Work time being used for wedding planning",
              "body" => include("Pam is spending"),
            ),
          ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
        v.begin_partner_outreach
        expect(tmpl_req).to have_been_made
        expect(req).to have_been_made
      end

      it "prefers the organization-specific template id" do
        Suma::Fixtures.organization.create(
          name: v.membership.unverified_organization_name,
          membership_verification_front_template_id: "rsp_fromorg",
        )

        tmpl_req = stub_request(:get, "https://api2.frontapp.com/message_templates/rsp_fromorg").
          to_return(json_response(load_fixture_data("front/message_template")))

        req = stub_request(:post, "https://api2.frontapp.com/channels/cha123/drafts").
          with(
            body: hash_including(
              "subject" => "Work time being used for wedding planning",
              "body" => include("Pam is spending"),
            ),
          ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
        v.begin_partner_outreach
        expect(tmpl_req).to have_been_made
        expect(req).to have_been_made
      end
    end
  end

  describe "begin_member_outreach" do
    let(:v) { Suma::Fixtures.organization_membership_verification.create }

    before(:each) do
      described_class.front_member_channel_id = "cha456"
    end

    it "calls Front and saves the response" do
      v.membership.member.update(name: "Patricia Monahan", phone: "12158631080")
      req = stub_request(:post, "https://api2.frontapp.com/channels/cha456/drafts").
        with(
          body: {
            subject: "",
            body: "Hi Patricia Monahan",
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

    it "uses the current admin as the author (test edge cases with begin_partner_outreach)" do
      admin = Suma::Fixtures.member.create(email: "paula_pagac@ebert.test")
      teammate_req = stub_request(:get, "https://api2.frontapp.com/teammates/alt:email:paula_pagac@ebert.test").
        to_return(json_response(load_fixture_data("front/teammate")))
      draft_req = stub_request(:post, "https://api2.frontapp.com/channels/cha456/drafts").
        with(
          body: hash_including("author_id" => "tea_6r55a"),
        ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
      Suma.set_request_user_and_admin(nil, admin) do
        v.begin_member_outreach
      end
      expect(teammate_req).to have_been_made
      expect(draft_req).to have_been_made
    end

    describe "template usage" do
      before(:each) do
        described_class.front_member_default_en_template_id = "rsp_englishdefault"
        described_class.front_member_default_es_template_id = "rsp_spanishdefault"
      end

      it "uses the default, language-specific member template text if set" do
        tmpl_req = stub_request(:get, "https://api2.frontapp.com/message_templates/rsp_spanishdefault").
          to_return(json_response(load_fixture_data("front/message_template")))
        v.membership.member.preferences!.update(preferred_language: "es")

        req = stub_request(:post, "https://api2.frontapp.com/channels/cha456/drafts").
          with(
            body: hash_including(
              "subject" => "Work time being used for wedding planning",
              "body" => include("Pam is spending"),
            ),
          ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
        v.begin_member_outreach
        expect(tmpl_req).to have_been_made
        expect(req).to have_been_made
      end

      it "prefers the organization-specific localized template id" do
        Suma::Fixtures.organization.create(
          name: v.membership.unverified_organization_name,
          membership_verification_member_outreach_template: Suma::TranslatedText.create(
            en: "rsp_englishorg",
            es: "rsp_spanishorg",
          ),
        )

        v.membership.member.preferences!.update(preferred_language: "en")

        tmpl_req = stub_request(:get, "https://api2.frontapp.com/message_templates/rsp_englishorg").
          to_return(json_response(load_fixture_data("front/message_template")))
        req = stub_request(:post, "https://api2.frontapp.com/channels/cha456/drafts").
          with(
            body: hash_including(
              "subject" => "Work time being used for wedding planning",
              "body" => include("Pam is spending"),
            ),
          ).to_return(json_response(load_fixture_data("front/channel_create_draft")))
        v.begin_member_outreach
        expect(tmpl_req).to have_been_made
        expect(req).to have_been_made
      end
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
          waiting_on_member: false,
          initial_draft: true,
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
          initial_draft: false,
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

  describe "notes" do
    it "renders markdown to html" do
      v = Suma::Fixtures.organization_membership_verification.create
      note = v.add_note(content: "hello **there**", created_at: Time.now)
      expect(note.content_html).to eq("hello <strong>there</strong>")
    end
  end
end
