# frozen_string_literal: true

require "suma/rakeutil"

RSpec.describe Suma::Rakeutil do
  describe "readall_nonblock" do
    it "reads the full io" do
      s = +""
      num_digits = 1024 * rand(6..12) * (1 + rand)
      (1..num_digits).each { |i| s << "#{i}_" }
      Tempfile.create do |tf|
        tf << s
        tf.flush
        tf.rewind
        got = described_class.readall_nonblock(tf)
        expect(got).to eq(s)
      end
    end

    it "returns empty string if the io is empty" do
      Tempfile.create do |tf|
        got = described_class.readall_nonblock(tf)
        expect(got).to eq("")
      end
    end

    it "returns nil if the io blocked" do
      reader, _writer = IO.pipe
      got = described_class.readall_nonblock(reader)
      expect(got).to be_nil
    end
  end
end
