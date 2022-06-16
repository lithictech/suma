# frozen_string_literal: true

RSpec.describe "auth", :integration do
  let(:password) { Suma::Fixtures::Members::PASSWORD }

  it "allows me to sign up" do
    customer = Suma::Fixtures.customer.instance

    login_resp = post(
      "/api/v1/register",
      body: {
        email: customer.email,
        password:,
        phone: customer.phone,
        timezone: "America/Los_Angeles",
      },
    )
    expect(login_resp).to party_status(200)

    customer_resp = get("/api/v1/me")
    expect(customer_resp).to party_status(200)
  end

  it "allows me to log in and out" do
    customer = Suma::Fixtures.customer.password(password).create

    login_resp = post("/api/v1/auth", body: {email: customer.email, password:})
    expect(login_resp).to party_status(200)
    expect(login_resp).to party_response(match(hash_including(name: customer.name)))

    customer_resp = get("/api/v1/me")
    expect(customer_resp).to party_status(200)

    logout_resp = delete("/api/v1/auth")
    expect(logout_resp).to party_status(204)
  end

  it "signs me in if I sign up but already have an account with that email/password" do
    customer = Suma::Fixtures.customer.password(password).create

    login_resp = post(
      "/api/v1/register",
      body: {
        email: customer.email,
        password:,
        name: customer.name,
        phone: customer.phone,
        timezone: "America/Los_Angeles",
      },
    )
    expect(login_resp).to party_status(200)
    expect(login_resp).to party_response(match(hash_including(id: customer.id)))
  end

  it "can forget and reset a password" do
    customer = Suma::Fixtures.customer.create

    forgot_resp = post("/api/v1/me/forgot_password", body: {email: customer.email})
    expect(forgot_resp).to party_status(202)

    expect(customer.reset_codes).to have_attributes(length: 1)
    token = customer.reset_codes.first

    reset_resp = post("/api/v1/me/reset_password", body: {token: token.token, password: "test1234reset"})
    expect(reset_resp).to party_status(200)

    get_customer_resp = get("/api/v1/me")
    expect(get_customer_resp).to party_status(200)
  end

  it "can access admin endpoints only if the customer authed as an admin and retains the role" do
    customer = Suma::Fixtures.customer.admin.instance
    auth_customer(customer)

    resp = get("/api/v1/auth")
    expect(resp).to party_status(200)
    expect(resp).to party_response(match(hash_including(name: customer.name)))

    customer.remove_role(Suma::Role.admin_role)

    resp = get("/api/v1/auth")
    expect(resp).to party_status(401)
  end
end
