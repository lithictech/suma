# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "a hybrid searchable object" do
  let(:instance) { raise "must be defined in block" }

  it "returns search document text" do
    t = instance.hybrid_search_text
    expect(t).to be_present
  end
end
