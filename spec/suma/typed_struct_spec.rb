# frozen_string_literal: true

RSpec.describe Suma::TypedStruct do
  describe "inspect" do
    it "renders all accessors" do
      t = Class.new(described_class) do
        attr_accessor :x, :y

        def a = :a
        def b(_) = :b
        def z = :z

        def z=(_)
          :not_see_this
        end
      end
      expect(t.new(x: "x", y: :y).inspect).to eq('(a: :a, x: "x", y: :y, z: :z)')
      t.new.z = 5 # Used to hit coverage on the z= method
      expect(t.new(x: 1).x).to eq(1)
      expect(t.new(x: 1)[:x]).to eq(1)
    end
  end

  describe "as_json" do
    it "includes all fields" do
      t = Class.new(described_class) do
        attr_accessor :x, :y, :z

        def _defaults = {z: 5}
      end
      expect(t.new(x: 5).as_json).to eq({"x" => 5, "y" => nil, "z" => 5})
    end
  end

  describe "requires" do
    it "errors if required fields are not set on init" do
      t = Class.new(described_class) do
        attr_accessor :x, :y, :z

        requires :x, :z
      end
      expect { t.new(x: 1, z: 1) }.to_not raise_error
      expect { t.new(x: 1) }.to raise_error(ArgumentError)
      expect { t.new(z: 1) }.to raise_error(ArgumentError)
    end

    it "requires all readonly fields with all:true" do
      t = Class.new(described_class) do
        attr_reader :x, :y
        attr_accessor :z

        requires(all: true)
      end
      expect { t.new(x: 1, y: 1) }.to_not raise_error
      expect { t.new(x: 1) }.to raise_error(ArgumentError)
      expect { t.new(y: 1) }.to raise_error(ArgumentError)
    end

    it "can use requires multiple times" do
      t = Class.new(described_class) do
        attr_accessor :x, :y, :z

        requires :x
        requires :y
      end
      expect { t.new(x: 1, y: 1) }.to_not raise_error
      expect { t.new(x: 1) }.to raise_error(ArgumentError)
      expect { t.new(y: 1) }.to raise_error(ArgumentError)
    end

    it "does not require defaults" do
      t = Class.new(described_class) do
        attr_reader :x, :y

        def _defaults = {x: 1}
        requires(all: true)
      end
      expect { t.new(y: 1) }.to_not raise_error
      expect { t.new(x: 1) }.to raise_error(ArgumentError)
    end
  end
end
