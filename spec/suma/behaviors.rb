# frozen_string_literal: true

require "rspec"

RSpec.shared_examples "a hybrid searchable object" do
  let(:instance) { raise "must be defined in block" }

  it "returns search document text" do
    t = instance.hybrid_search_text
    expect(t).to be_present
  end

  it "can bulk reindex", hybrid_search: true do
    t = instance
    expect(t).to have_attributes(search_content: nil)
    instance.class.hybrid_search_reindex_all
    expect(t.refresh).to have_attributes(search_content: be_present)
  end
end
