# frozen_string_literal: true

require "suma/concurrency"

RSpec.describe Suma::Concurrency do
  describe "atomic_write" do
    include_context "uses temp dir"
    let(:path) { temp_dir_path + "testfile" }

    it "writes to the target" do
      described_class.atomic_write(path) do |f|
        f << "hi"
      end
      expect(File.read(path)).to eq("hi")
    end

    it "does not cause an issue with existing open handles" do
      File.write(path, "orig")
      h = File.open(path)
      described_class.atomic_write(path) do |f|
        f << "newdata"
      end
      expect(h.read).to eq("orig")
      expect(File.read(path)).to eq("newdata")
    end

    it "handles binary data" do
      # Cannot get this test to fail with any combination of bytes,
      # but we want to exercise the code paths anyway.
      b = "\u0000"
      described_class.atomic_write(path, mode: "wb") do |f|
        f << b
      end
      expect(File.binread(path)).to eq(b)
    end

    it "does not delete the new file" do
      described_class.atomic_write(path) do |f|
        f << "hi"
      end
      GC.start
      expect(File.read(path)).to eq("hi")
    end
  end
end
