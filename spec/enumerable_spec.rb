# frozen_string_literal: true

require "suma/enumerable"

RSpec.describe Suma::Enumerable do
  describe "group_and_count_by" do
    it "groups and counts by the given block" do
      arr = [1, 3, 5, 2]
      result = described_class.group_and_count_by(arr, &:even?)
      expect(result).to eq(true => 1, false => 3)
    end
  end

  describe "group_and_count" do
    it "groups and counts with an identity block" do
      arr = [:a, :b, :a, :c]
      result = described_class.group_and_count(arr)
      expect(result).to eq(a: 2, b: 1, c: 1)
    end
  end

  describe "one!" do
    it "returns the only item, or raises" do
      expect { described_class.one!([]) }.to raise_error(ArgumentError)
      expect(described_class.one!([1])).to eq(1)
      expect(described_class.one!([nil])).to be_nil
      expect { described_class.one!([nil, nil]) }.to raise_error(ArgumentError)
      expect { described_class.one!([1, 1]) }.to raise_error(ArgumentError)
    end
  end
end
