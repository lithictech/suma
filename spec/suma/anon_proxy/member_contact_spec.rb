# frozen_string_literal: true

RSpec.describe "Suma::AnonProxy::MemberContact", :db do
  let(:described_class) { Suma::AnonProxy::MemberContact }

  it "schedules a cleanup on destroy", sidekiq: :fake do
    mc = Suma::Fixtures.anon_proxy_member_contact.email("x@y.z").create(external_relay_id: "123")
    mc.destroy
    expect(Suma::Async::AnonProxyMemberContactDestroyedResourceCleanup.jobs).to contain_exactly(
      include("args" => [{"address" => "x@y.z", "external_id" => "123", "relay_key" => "fake-email-relay"}]),
    )
  end
end
