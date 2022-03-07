# frozen_string_literal: true

require "money"

require "suma/moneyutil"

RSpec.describe Suma::Moneyutil do
  describe "divide" do
    it "can divide odds cents into an array" do
      m = Money.new(201)
      expect(described_class.divide(m, 1)).to eq([Money.new(201)])
      expect(described_class.divide(m, 2)).to eq([Money.new(101), Money.new(100)])
      expect(described_class.divide(m, 3)).to eq([Money.new(67), Money.new(67), Money.new(67)])
      expect(described_class.divide(m, 4)).to eq([Money.new(51), Money.new(50), Money.new(50), Money.new(50)])
    end

    it "can divide even cents into an array" do
      m = Money.new(200)
      expect(described_class.divide(m, 1)).to eq([Money.new(200)])
      expect(described_class.divide(m, 2)).to eq([Money.new(100), Money.new(100)])
      expect(described_class.divide(m, 3)).to eq([Money.new(67), Money.new(67), Money.new(66)])
    end
  end
end
