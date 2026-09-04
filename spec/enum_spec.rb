# frozen_string_literal: true

require "suma/enum"

RSpec.describe Suma::Enum do
  let(:host) do
    Module.new do
      define_singleton_method :name do
        "ModX"
      end
    end
  end

  it "can define and search enums" do
    reg = []
    x = described_class.define(host, :FakeTestEnum, [:a, :b, :c], registry: reg)
    expect(x::NAME).to eq(:FakeTestEnum)
    expect(x::VALUES).to eq([:a, :b, :c])
    expect(x.respond_to?(:a)).to be(true)
    expect(x.a).to eq(:a)
    expect(x.respond_to?(:z)).to be(false)
    expect(reg).to contain_exactly(
      have_attributes(host:, name: :FakeTestEnum, fqn: "ModX::FakeTestEnum", values: [:a, :b, :c]),
    )
  end
end
