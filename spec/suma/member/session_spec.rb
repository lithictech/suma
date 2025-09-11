# frozen_string_literal: true

RSpec.describe "Suma::Member::Session", :db do
  let(:described_class) { Suma::Member::Session }

  it "knows about impersonation" do
    m = Suma::Fixtures.member.create
    s = Suma::Fixtures.session.create(member: m)
    expect(s).to have_attributes(
      member: be === m,
      impersonation?: false,
      impersonating: nil,
      public_user: be === m,
    )
    m2 = Suma::Fixtures.member.create
    s.impersonate(m2)
    expect(s).to have_attributes(
      member: be === m,
      impersonation?: true,
      impersonating: be === m2,
      public_user: be === m2,
    )
    s.unimpersonate
    expect(s).to have_attributes(
      member: be === m,
      impersonation?: false,
      impersonating: nil,
      public_user: be === m,
    )
  end
end
