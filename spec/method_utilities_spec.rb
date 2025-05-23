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

      @w = 0
      singleton_attr_writer :w
      def self.w = @w * 10
    end

    expect(t.x).to eq(1)
    t.x = 2
    expect(t.x).to eq(2)

    expect(t.p?).to be(true)
    t.p = nil
    expect(t.p?).to be(false)

    expect(t.w).to eq(0)
    t.w = 5
    expect(t.w).to eq(50)
  end

  it "can set timestamps based on bool/time/nil inputs" do
    t = Class.new do
      attr_accessor :updated_at

      def updated? = Suma::MethodUtilities.timestamp_set?(self, :updated_at)

      def updated=(t)
        Suma::MethodUtilities.timestamp_set(self, :updated_at, t)
      end
    end
    m = t.new
    expect(m.updated_at).to be_nil
    expect(m.updated?).to be(false)

    m.updated = true
    expect(m.updated_at).to match_time(:now)
    expect(m.updated?).to be(true)

    t = 4.hours.ago
    m.updated = t
    expect(m.updated_at).to match_time(t)
    m.updated = true
    expect(m.updated_at).to match_time(t)

    m.updated = false
    expect(m.updated_at).to be_nil
    m.updated = nil
    expect(m.updated_at).to be_nil
  end
end
