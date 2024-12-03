# frozen_string_literal: true

require "suma/fixtures"

RSpec.describe Suma::Fixtures do
  it "sets the path prefix for fixtures" do
    expect(described_class.fixture_path_prefix).to eq("suma/fixtures")
  end

  it "can call all decorators (improve fixture coverage)", db: true do
    # This is gross, but we want to have coverage of fixtures. Ideally each decorator is tested
    # but in many cases it isn't really worth it.
    member = Suma::Fixtures.member.create
    Suma::Fixtures.anon_proxy_vendor_configuration.sms.create
    Suma::Fixtures.bank_account.with_legal_entity.create
    Suma::Fixtures.card.with_legal_entity.create
    Suma::Fixtures.funding_transaction.with_fake_strategy.member(member).create
    Suma::Fixtures.geolocation.latlng(10, 2).instance
    Suma::Fixtures.legal_entity.with_contact_info.with_address.create
    Suma::Fixtures.member_activity.create
    Suma::Fixtures.member.password.plus_sign.with_email.with_phone.terms_agreed.create
    Suma::Fixtures.message_delivery.extra("x", "y").create
    Suma::Fixtures.payment_trigger.inactive.create
    Suma::Fixtures.payout_transaction.with_fake_strategy.member(member).create
    Suma::Fixtures.reset_code.email.create
    Suma::Fixtures.translated_text.empty.create
    Suma::Fixtures.uploaded_file.uploaded_1x1_png.uploaded_bytes("x", "text/plain").create
  end
end
