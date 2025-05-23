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
end
