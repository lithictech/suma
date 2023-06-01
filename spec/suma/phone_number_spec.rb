# frozen_string_literal: true

RSpec.describe Suma::PhoneNumber do
  describe Suma::PhoneNumber::US do
    it "can format a normalized number as US" do
      expect(described_class.format("13334445555")).to eq("(333) 444-5555")
    end

    it "errors if the number is not normalized" do
      expect { described_class.format("3334445555") }.to raise_error(ArgumentError)
    end
  end
end
