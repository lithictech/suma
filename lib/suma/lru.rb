# frozen_string_literal: true

# LRU cache for Ruby.
# Search for 'lru cache Ruby' for the implementations this was based on,
# since Ruby hashes are ordered it's really easy to build
# and there aren't really packages for it.
class Suma::Lru
  def initialize(max_size)
    @max_size = max_size
    @container = {}
  end

  def [](key)
    found = true
    value = @container.delete(key) { found = false }
    return unless found
    @container[key] = value
    return value
  end

  def []=(key, val)
    @container.delete(key)
    @container[key] = val
    @container.delete(@container.first[0]) if @container.length > @max_size
    # rubocop:disable Lint/ReturnInVoidContext
    # Mimic Ruby's hash, which works this way
    return val
    # rubocop:enable Lint/ReturnInVoidContext
  end

  def size = @container.size
  def length = @container.length
  def empty? = @container.empty?
  def include?(key) = @container.include?(key)
end
