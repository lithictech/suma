# frozen_string_literal: true

require "rspec"
require "suma/spec_helpers/testing_helpers"

RSpec.shared_examples "a funding transaction payment strategy" do
  include Suma::SpecHelpers::TestingHelpers

  it "implements all abstract methods" do
    assert_implemented { strategy.short_name }
    assert_implemented { strategy.admin_details_typed }
    assert_implemented { strategy.check_validity }
    assert_implemented { strategy.supports_refunds? }
    assert_implemented { strategy.originating_instrument_label }
    assert_implemented { strategy.ready_to_collect_funds? }
    assert_implemented { strategy.collect_funds }
    assert_implemented { strategy.funds_cleared? }
    assert_implemented { strategy.funds_canceled? }
  end
end

RSpec.shared_examples "a payout transaction payment strategy" do
  include Suma::SpecHelpers::TestingHelpers

  it "implements all abstract methods" do
    assert_implemented { strategy.short_name }
    assert_implemented { strategy.admin_details_typed }
    assert_implemented { strategy.check_validity }
    assert_implemented { strategy.ready_to_send_funds? }
    assert_implemented { strategy.send_funds }
    assert_implemented { strategy.funds_settled? }
    assert_implemented { strategy.send_failed? }
  end
end

RSpec.shared_examples "a payment strategy with a deletable instrument" do
  def delete_instrument = raise NotImplementedError
  it "should fail validation if soft deleted" do
    expect(strategy.check_validity).to be_empty
    delete_instrument
    expect(strategy.check_validity).to include(match(/deleted and cannot be used/))
  end
end

RSpec.shared_examples "a payment strategy with a verifiable instrument" do
  def unverify_instrument = raise NotImplementedError
  it "should fail validation if not verified" do
    expect(strategy.check_validity).to be_empty
    unverify_instrument
    expect(strategy.check_validity).to include(match(/not verified and cannot be used/))
  end
end

RSpec.shared_examples "a payment instrument" do
  let(:instrument) { Suma::Fixtures.fixture_module_for(described_class).base_factory.create }

  it "knows about itself" do
    expect(instrument).to have_attributes(
      payment_method_type: be_a(String),
      name: be_a(String).and(be_present),
      institution_name: be_a(String),
      legal_entity: be_a(Suma::LegalEntity),
      expired?: be_bool,
      verified?: be_bool,
      soft_deleted?: be_bool,
      status: be_a(Symbol),
    )
    expect(instrument.usable_for_funding?).to be_bool
    expect(instrument.usable_for_payout?).to be_bool
    expect(instrument).to respond_to(:refetch_remote_data), "must be implemented on concrete classes"

    expect(described_class.dataset).to respond_to(:not_soft_deleted)
    expect(described_class.dataset).to respond_to(:usable_for_funding)
    expect(described_class.dataset).to respond_to(:usable_for_payout)
    expect(described_class.dataset).to respond_to(:expired_as_of)
    expect(described_class.dataset).to respond_to(:unexpired_as_of)

    expect { described_class.dataset.not_soft_deleted.all }.to_not raise_error
    expect { described_class.dataset.usable_for_funding.all }.to_not raise_error
    expect { described_class.dataset.usable_for_payout.all }.to_not raise_error
    expect { described_class.dataset.expired_as_of(Time.now).all }.to_not raise_error
    expect { described_class.dataset.unexpired_as_of(Time.now).all }.to_not raise_error
  end

  it "can be represented as a payment instrument" do
    ins = instrument
    pi = Suma::Payment::Instrument.first
    expect(pi).to_not be_nil
    expect(pi).to have_attributes(
      payment_method_type: ins.payment_method_type,
      name: ins.name,
      institution_name: ins.institution_name,
      legal_entity: ins.legal_entity,
      expired?: ins.expired?,
      verified?: ins.verified?,
      soft_deleted?: ins.soft_deleted?,
    )
  end
end
