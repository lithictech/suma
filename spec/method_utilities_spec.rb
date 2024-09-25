# frozen_string_literal: true

require "suma/method_utilities"

RSpec.describe Suma::MethodUtilities do
  it "can create class and instance accessors, readers, and predicates" do
    t = Class.new do
      extend Suma::MethodUtilities

      singleton_attr_accessor :x
      @x = 1
      singleton_method_alias :y, :x
      singleton_predicate_reader :p
      @p = 10
      singleton_predicate_accessor :p
    end

    expect(t.x).to eq(1)
    t.x = 2
    expect(t.x).to eq(2)

    expect(t.p?).to be(true)
    t.p = nil
    expect(t.p?).to be(false)
  end
end
