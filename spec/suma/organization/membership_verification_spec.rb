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
      expect(v.refresh).to have_attributes(partner_outreach_front_response: hash_including("id" => "msg_1q15qmtq"))
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
      expect(v.refresh).to have_attributes(member_outreach_front_response: hash_including("id" => "msg_1q15qmtq"))
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
end
