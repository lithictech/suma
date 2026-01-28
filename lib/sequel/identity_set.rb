# frozen_string_literal: true

# Set-like object that uses object primary keys as their unique field,
# rather than hashing or object identity.
class Sequel::IdentitySet
  include Enumerable

  class << self
    def flatten(*sets)
      return self.new if sets.empty?
      result = self.new
      sets.each do |st|
        result.merge!(st)
      end
      return result
    end
  end

  def initialize
    @hash = {}
  end

  def each(&)
    return enum_for(:each) unless block_given?
    @hash.each_value(&)
  end

  def add(item)
    @hash[item.pk] = item
  end

  alias << add

  # @param [Sequel::IdentitySet] other
  def merge!(other)
    @hash.merge!(other.internal_hash)
  end

  protected def internal_hash = @hash

  def include?(o) = @hash.key?(o.pk)

  def to_s = "#{self.class}{#{@hash.values}}"
  def inspect = "#{self.class}{#{@hash.values.inspect}}"
end
