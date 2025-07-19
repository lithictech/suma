# frozen_string_literal: true

require "suma/i18n"

RSpec.describe Suma::I18n::Formatter do
  it "can figure out the formatter for a string" do
    expect(described_class.for("ab")).to eq(described_class::STR)
    expect(described_class.for("a **b**")).to eq(described_class::MD)
    expect(described_class.for("a\n\nz\n\n-b\n-c\n")).to eq(described_class::MD_MULTILINE)
    expect(described_class.for("hi\n\n- a\n- b")).to eq(described_class::MD_MULTILINE)
    expect(described_class.for("hi\n- a\n- b")).to eq(described_class::STR)
    expect(described_class.for("- a\n- b")).to eq(described_class::MD_MULTILINE)
    expect(described_class.for("hi\n1. a\n2. b")).to eq(described_class::STR)
    expect(described_class.for("hi\n\n1. a\n2. b")).to eq(described_class::MD_MULTILINE)
    expect(described_class.for("1. a\n2. b")).to eq(described_class::MD_MULTILINE)
  end

  it "uses an LRU" do
    orig_size = described_class.lru.size
    s1 = SecureRandom.hex
    s2 = SecureRandom.hex
    expect(described_class.for(s1)).to eq(described_class::STR)
    expect(described_class.for(s1)).to eq(described_class::STR)
    expect(described_class.lru).to have_attributes(size: orig_size + 1)
    expect(described_class.for(s2)).to eq(described_class::STR)
    expect(described_class.lru).to have_attributes(size: orig_size + 2)
  end
end
