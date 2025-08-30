# frozen_string_literal: true

RSpec.describe Suma::SimpleRegistry do
  let(:base_cls) do
    Class.new do
      extend Suma::SimpleRegistry
    end
  end
  let(:subcls) { Class.new }
  let(:subclsargs) do
    Class.new(base_cls) do
      attr_reader :x, :y

      def initialize(x, y:)
        @x = x
        @y = y
        super()
      end
    end
  end

  it "can lookup and create registered items" do
    base_cls.register(:sub, subcls)
    expect(base_cls.registry_lookup!(:sub)).to eq(subcls)
    expect(base_cls.registry_create!(:sub)).to be_a(subcls)
    expect { base_cls.registry_lookup!(:nope) }.to raise_error(described_class::Unregistered, /nope not in/)
    expect { base_cls.registry_lookup!(nil) }.to raise_error(described_class::Unregistered, /key cannot be blank/)
    expect { base_cls.registry_lookup!(" ") }.to raise_error(described_class::Unregistered, /key cannot be blank/)
  end

  it "initializes classes with registered arguments" do
    base_cls.register(:sub, subclsargs, "xval", y: "yval")
    expect(base_cls.registry_lookup!(:sub)).to eq(subclsargs)
    expect(base_cls.registry_create!(:sub)).to be_a(subclsargs)
    expect(base_cls.registry_create!(:sub)).to have_attributes(x: "xval", y: "yval")
  end

  it "can iterate created registry items" do
    base_cls.register(:sub1, subclsargs, 1, y: 1)
    base_cls.register(:sub2, subclsargs, 2, y: 2)
    base_cls.register(:sub3, subclsargs, 3, y: 3)
    got = base_cls.registry_each.to_a
    expect(got).to contain_exactly(
      have_attributes(x: 1),
      have_attributes(x: 2),
      have_attributes(x: 3),
    )
    got2 = []
    base_cls.registry_each { |r| got2 << r }
    expect(got2).to have_length(3)
  end

  it "can use register and create args" do
    base_cls.register(:sub1, subclsargs, "x1val")
    base_cls.register(:sub2, subclsargs, y: "y2val")
    expect(base_cls.registry_create!(:sub1, y: "y1val")).to have_attributes(x: "x1val", y: "y1val")
    expect(base_cls.registry_create!(:sub2, "x2val")).to have_attributes(x: "x2val", y: "y2val")
  end

  it "can override the registered item" do
    base_cls.register(:sub1, subcls)
    base_cls.registry_override = :sub1
    expect(base_cls.registry_lookup!(:x)).to eq(subcls)
  ensure
    base_cls.registry_override = nil
  end
end
