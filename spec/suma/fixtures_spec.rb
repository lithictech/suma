# frozen_string_literal: true

require "suma/fixtures"

RSpec.describe Suma::Fixtures, db: true  do
  it "sets the path prefix for fixtures" do
    expect(described_class.fixture_path_prefix).to eq("suma/fixtures")
  end

  describe "nilor" do
    it "returns val if x is nil" do
      expect(described_class.nilor(nil, 1)).to eq(1)
      expect(described_class.nilor(false, 2)).to eq(false)
    end
  end

  describe "can fixture" do
    standard_modules = Suma::Fixtures.fixture_modules
    standard_modules.each do |mod|
      it mod.to_s do
        factory = mod.base_factory
        factory = mod.ensure_fixturable(factory)
        if mod.fixtured_class.method_defined?(:save)
          factory.create
        else
          factory.instance
        end
      end
    end
  end

  it "can call all decorators (improve fixture coverage)" do
    # This is gross, but we want to have coverage of fixtures. Ideally each decorator is tested
    # but in many cases it isn't really worth it.
    member = Suma::Fixtures.member.create
    Suma::Fixtures.anon_proxy_vendor_configuration.disabled.with_programs({}).create
    Suma::Fixtures.bank_account.with_legal_entity.create
    Suma::Fixtures.card.with_legal_entity.create
    Suma::Fixtures.funding_transaction.with_fake_strategy.member(member).create
    Suma::Fixtures.geolocation.latlng(10, 2).instance
    Suma::Fixtures.legal_entity.with_contact_info.with_address.create
    Suma::Fixtures.member_activity.create
    Suma::Fixtures.member.password.plus_sign.with_email.with_phone.terms_agreed.create
    Suma::Fixtures.message_delivery.extra("x", "y").create
    Suma::Fixtures.offering.description("hello").create
    Suma::Fixtures.payment_trigger.inactive.create
    Suma::Fixtures.payout_transaction.with_fake_strategy.member(member).create
    Suma::Fixtures.program.with_(Suma::Fixtures.offering.create).create
    Suma::Fixtures.reset_code.create
    Suma::Fixtures.translated_text.empty.create
    Suma::Fixtures.uploaded_file.uploaded_bytes("x", "text/plain").create
    Suma::Fixtures.uploaded_file.uploaded_1x1_png.create
  end

  it "keeps track of fixture and fixtured classes" do
    expect(Suma::Fixtures.fixture_modules).to include(Suma::Fixtures::Members)
    expect(Suma::Fixtures.fixtured_classes).to include(Suma::Member)
    expect(Suma::Fixtures.fixture_module_for(Suma::Member)).to eq(Suma::Fixtures::Members)
  end
end
