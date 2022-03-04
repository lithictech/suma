# frozen_string_literal: true

RSpec.describe "helpers", :integration do
  it "work (auth_customer with no argument creates and logs in new customer)" do
    customer = auth_customer
    expect(customer).to be_an_instance_of(Suma::Customer)
    expect(customer).to be_saved

    resp = get("/v1/me")
    expect(resp).to party_status(200)
    expect(resp).to party_response(include(id: customer.id))
  end

  it "work (auth_customer with customer logs in customer)" do
    customer = Suma::Fixtures.customer.create
    got_customer = auth_customer(customer)
    expect(got_customer).to be === customer

    resp = get("/v1/me")
    expect(resp).to party_status(200)
    expect(resp).to party_response(include(id: customer.id))
  end
end
