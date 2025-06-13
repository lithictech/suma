# frozen_string_literal: true

RSpec.describe Suma::SimpleRegistry do
  base_cls = Class.new do
    extend Suma::SimpleRegistry
  end
  sub1 = Class.new(base_cls) do
  end
  base_cls.register(:sub1, sub1)

  it "can lookup and create registered items" do
    expect(base_cls.registry_lookup!(:sub1)).to eq(sub1)
    expect(base_cls.registry_create!(:sub1)).to be_a(sub1)
    expect { base_cls.registry_lookup!(:nope) }.to raise_error(described_class::Unregistered)
  end

  it "can override the registered item" do
    base_cls.registry_override = :sub1
    expect(base_cls.registry_lookup!(:x)).to eq(sub1)
  ensure
    base_cls.registry_override = nil
  end
end
