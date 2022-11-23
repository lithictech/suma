# frozen_string_literal: true

module Grape::DSL::InsideRoute
  # Grape #stream sets cache-control explicitly, so stomp it if needed.
  # I believe it's a bug, and used Rails as inspiration,
  # which also had a bug: https://github.com/rails/rails/pull/35400
  alias _original_stream stream

  def stream(value=nil)
    orig = header["Cache-Control"]
    r = _original_stream(value)
    header "Cache-Control", orig unless orig.nil?
    return r
  end
end
