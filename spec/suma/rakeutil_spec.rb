# frozen_string_literal: true

require "suma/rakeutil"

RSpec.describe Suma::Rakeutil do
  describe "readall" do
    it "reads the full io" do
      s = +""
      num_digits = 1024 * rand(6..12) * (1 + rand)
      (1..num_digits).each do |i|
        s << "#{i}_"
        s << "\n" if (i % 10).zero?
      end
      Tempfile.create do |tf|
        tf << s
        tf.flush
        tf.rewind
        got = described_class.readall(tf)
        expect(got).to eq(s)
      end
    end

    it "returns empty string if the io is empty" do
      Tempfile.create do |tf|
        got = described_class.readall(tf)
        expect(got).to eq("")
      end
    end
  end
end
