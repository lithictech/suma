# frozen_string_literal: true

RSpec.describe "auth", :integration do
  let(:password) { Suma::Fixtures::Members::PASSWORD }

  it "allows me to sign up" do
    member = Suma::Fixtures.member.instance

    login_resp = post(
      "/api/v1/auth/start",
      body: {phone: member.phone, timezone: "America/Los_Angeles"},
    )
    expect(login_resp).to party_status(200)

    me = Suma::Member[phone: member.phone]
    verify_resp = post(
      "/api/v1/auth/verify",
      body: {phone: me.phone, token: me.reset_codes.last.token},
    )
    expect(verify_resp).to party_status(200)

    member_resp = get("/api/v1/me")
    expect(member_resp).to party_status(200)
  end

  it "allows me to log in and out" do
    me = Suma::Fixtures.member.create

    login_resp = post(
      "/api/v1/auth/start",
      body: {phone: me.phone, timezone: "America/Los_Angeles"},
    )
    expect(login_resp).to party_status(200)

    verify_resp = post(
      "/api/v1/auth/verify",
      body: {phone: me.phone, token: me.reset_codes.last.token},
    )
    expect(verify_resp).to party_status(200)

    member_resp = get("/api/v1/me")
    expect(member_resp).to party_status(200)
  end

  it "can access admin endpoints only if the member authed as an admin and retains the role" do
    member = Suma::Fixtures.member.admin.instance
    auth_member(member)

    resp = get("/api/v1/me")
    expect(resp).to party_status(200)
    resp = get("/adminapi/v1/auth")
    expect(resp).to party_status(200)

    member.remove_role(Suma::Role.admin_role)

    resp = get("/api/v1/me")
    expect(resp).to party_status(401)
    resp = get("/adminapi/v1/auth")
    expect(resp).to party_status(401)
  end

  it "cannot access admin endpoints without the admin role" do
    auth_member

    resp = get("/api/v1/me")
    expect(resp).to party_status(200)
    resp = get("/adminapi/v1/auth")
    expect(resp).to party_status(401)
    resp = get("/adminapi/v1/members")
    expect(resp).to party_status(401)
  end
end
