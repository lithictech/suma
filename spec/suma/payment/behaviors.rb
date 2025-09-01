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
  it "knows about itself" do
    expect(instrument).to have_attributes(
      payment_method_type: be_a(String),
      name: be_a(String).and(be_present),
      last4: be_a(String).and(be_present),
      can_use_for_funding?: be_bool,
      institution: be_a(Suma::Payment::Institution),
      legal_entity: be_a(Suma::LegalEntity),
    )
  end
end
