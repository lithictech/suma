# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "a payment instrument" do
  it "knows about itself" do
    expect(instrument).to have_attributes(payment_method_type: be_a(String))
    expect(instrument).to have_attributes(name: be_a(String).and(be_present))
  end

  it "can display itself" do
    expect(instrument).to have_attributes(to_display: be_a(Suma::Payment::Instrument::Display))
  end

  it "can render a legal entity" do
    expect(instrument).to have_attributes(legal_entity: be_a(Suma::LegalEntity))
    expect(instrument).to have_attributes(legal_entity_display: be_a(Suma::LegalEntity::Display))
  end
end
