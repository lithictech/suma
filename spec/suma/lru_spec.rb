# frozen_string_literal: true

require "suma/lru"

RSpec.describe Suma::Lru do
  it "acts like a sized-cache" do
    # Depend on the algorithm to be correct for speed
    h = described_class.new(2)
    expect(h).to have_attributes(empty?: true, size: 0, length: 0)
    expect(h[:a]).to be_nil
    expect(h).to have_attributes(empty?: true, size: 0, length: 0)
    expect(h[:a] = 1).to eq(1)
    h[:b] = 2
    expect(h).to have_attributes(size: 2)
    h[:c] = 3
    expect(h).to have_attributes(size: 2)
    expect(h).to_not include(:a)
    expect(h).to include(:b)
    expect(h).to include(:c)
    h[:b] = 2
    h[:a] = 1
    expect(h).to include(:a)
    expect(h).to include(:b)
    expect(h).to_not include(:c)
  end
end
