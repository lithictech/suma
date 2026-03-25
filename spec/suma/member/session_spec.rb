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

  describe "logout_member" do
    let(:member) { Suma::Fixtures.member.create }

    it "logs out of all active sessions" do
      sess = Suma::Fixtures.session.for(member).create
      t = 4.hours.ago
      sess2 = Suma::Fixtures.session.for(member).create(logged_out_at: t)
      expect(described_class.logout_member(member)).to eq(1)
      expect(sess.refresh).to have_attributes(logged_out_at: match_time(:now))
      expect(sess2.refresh).to have_attributes(logged_out_at: match_time(t))
    end

    it "can exclude session ids" do
      sess = Suma::Fixtures.session.for(member).create
      expect(described_class.logout_member(member, except: [sess.id])).to eq(0)
      expect(sess.refresh).to have_attributes(logged_out_at: be_nil)
    end
  end
end
