# frozen_string_literal: true

require "suma/fixtures"

RSpec.describe Suma::Fixtures do
  it "sets the path prefix for fixtures" do
    expect(described_class.fixture_path_prefix).to eq("suma/fixtures")
  end
end
