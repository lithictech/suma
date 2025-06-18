# frozen_string_literal: true

require "suma/frontapp"

RSpec.describe Suma::Frontapp do
  it "converts values to API ids" do
    expect(described_class.to_api_id("cnv", 1234)).to eq("cnv_ya")
    expect(described_class.to_api_id("cnv", "1234")).to eq("cnv_ya")
    expect(described_class.to_api_id("cnv", "cnv_1234")).to eq("cnv_1234")
    expect(described_class.to_api_id("cnv", "cnv_abc")).to eq("cnv_abc")
    expect(described_class.to_api_id("cnv", "")).to eq("")
    expect(described_class.to_api_id("cnv", nil)).to be_nil
    expect { described_class.to_api_id("cnv", "msg_123") }.to raise_exception(ArgumentError)
  end
end
