# frozen_string_literal: true

RSpec.describe "auth", :integration do
  let(:password) { Suma::Fixtures::Members::PASSWORD }

  it "allows me to sign up" do
    member = Suma::Fixtures.member.instance

    login_resp = post(
      "/api/v1/register",
      body: {
        email: member.email,
        password:,
        phone: member.phone,
        timezone: "America/Los_Angeles",
      },
    )
    expect(login_resp).to party_status(200)

    member_resp = get("/api/v1/me")
    expect(member_resp).to party_status(200)
  end

  it "allows me to log in and out" do
    member = Suma::Fixtures.member.password(password).create

    login_resp = post("/api/v1/auth", body: {email: member.email, password:})
    expect(login_resp).to party_status(200)
    expect(login_resp).to party_response(match(hash_including(name: member.name)))

    member_resp = get("/api/v1/me")
    expect(member_resp).to party_status(200)

    logout_resp = delete("/api/v1/auth")
    expect(logout_resp).to party_status(204)
  end

  it "signs me in if I sign up but already have an account with that email/password" do
    member = Suma::Fixtures.member.password(password).create

    login_resp = post(
      "/api/v1/register",
      body: {
        email: member.email,
        password:,
        name: member.name,
        phone: member.phone,
        timezone: "America/Los_Angeles",
      },
    )
    expect(login_resp).to party_status(200)
    expect(login_resp).to party_response(match(hash_including(id: member.id)))
  end

  it "can forget and reset a password" do
    member = Suma::Fixtures.member.create

    forgot_resp = post("/api/v1/me/forgot_password", body: {email: member.email})
    expect(forgot_resp).to party_status(202)

    expect(member.reset_codes).to have_attributes(length: 1)
    token = member.reset_codes.first

    reset_resp = post("/api/v1/me/reset_password", body: {token: token.token, password: "test1234reset"})
    expect(reset_resp).to party_status(200)

    get_member_resp = get("/api/v1/me")
    expect(get_member_resp).to party_status(200)
  end

  it "can access admin endpoints only if the member authed as an admin and retains the role" do
    member = Suma::Fixtures.member.admin.instance
    auth_member(member)

    resp = get("/api/v1/auth")
    expect(resp).to party_status(200)
    expect(resp).to party_response(match(hash_including(name: member.name)))

    member.remove_role(Suma::Role.admin_role)

    resp = get("/api/v1/auth")
    expect(resp).to party_status(401)
  end
end
