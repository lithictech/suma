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

  it "formats its address" do
    mc = Suma::Fixtures.anon_proxy_member_contact.email("x@y.z").create
    expect(mc.address).to eq("x@y.z")
    expect(mc.formatted_address).to eq("x@y.z")
    mc.set(phone: "15552223333", email: nil)
    expect(mc.address).to eq("15552223333")
    expect(mc.formatted_address).to eq("(555) 222-3333")
  end

  it "returns externals links based on the relay" do
    mc = Suma::Fixtures.anon_proxy_member_contact.phone.create
    expect(mc.external_links).to eq([])
    mc.set(relay_key: "signalwire", external_relay_id: "123")
    expect(mc.external_links).to eq(
      [{name: "Signalwire", url: "https://sumafaketest.signalwire.com/phone_numbers/123"}],
    )
  end
end
