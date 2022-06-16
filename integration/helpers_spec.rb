# frozen_string_literal: true

RSpec.describe "helpers", :integration do
  it "work (auth_member with no argument creates and logs in new member)" do
    member = auth_member
    expect(member).to be_an_instance_of(Suma::Member)
    expect(member).to be_saved

    resp = get("/api/v1/me")
    expect(resp).to party_status(200)
    expect(resp).to party_response(include(id: member.id))
  end

  it "work (auth_member with member logs in member)" do
    member = Suma::Fixtures.member.create
    got_member = auth_member(member)
    expect(got_member).to be === member

    resp = get("/api/v1/me")
    expect(resp).to party_status(200)
    expect(resp).to party_response(include(id: member.id))
  end
end
