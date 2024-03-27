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
          :z=
        end
      end
      expect(t.new(x: "x", y: :y).inspect).to eq('(a: :a, x: "x", y: :y, z: :z)')
    end
  end
end
