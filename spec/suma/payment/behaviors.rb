# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "a funding transaction payment strategy" do
  it "implements all abstract methods", on_potential_false_positives: :nothing do
    run_error_test { strategy.short_name }
    run_error_test { strategy.admin_details_typed }
    run_error_test { strategy.check_validity }
    run_error_test { strategy.supports_refunds? }
    run_error_test { strategy.originating_instrument_label }
    run_error_test { strategy.ready_to_collect_funds? }
    run_error_test { strategy.collect_funds }
    run_error_test { strategy.funds_cleared? }
    run_error_test { strategy.funds_canceled? }
  end

  def run_error_test
    # Go the long way around to avoid the rspect warning of on_potential_false_positives
    yield
  rescue WebMock::NetConnectNotAllowedError
    # We expect we'll hit these at times because we aren't doing faking for these behavior tests.
    nil
  rescue StandardError => e
    expect(e).to_not be_a(NotImplementedError)
  end
end

RSpec.shared_examples "a payout transaction payment strategy" do
  it "implements all abstract methods", on_potential_false_positives: :nothing do
    run_error_test { strategy.short_name }
    run_error_test { strategy.admin_details_typed }
    run_error_test { strategy.check_validity }
    run_error_test { strategy.ready_to_send_funds? }
    run_error_test { strategy.send_funds }
    run_error_test { strategy.funds_settled? }
  end

  def run_error_test
    # Go the long way around to avoid the rspect warning of on_potential_false_positives
    yield
  rescue WebMock::NetConnectNotAllowedError
    # We expect we'll hit these at times because we aren't doing faking for these behavior tests.
    nil
  rescue StandardError => e
    expect(e).to_not be_a(NotImplementedError)
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
