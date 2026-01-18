# frozen_string_literal: true

require "io/wait"

module Suma::Rakeutil
  # Read all the data from the IO.
  # Use each_line since that seems to be the only thing that works reliably
  # with nonblocking and blocking IO and without a ton of hoops.
  # To test with nonblocking IO, do something like:
  #   ( sleep 5; echo "hello" ) | bundle exec rake mobility:sync:limereport
  module_function def readall(io)
    buffer = +""
    io.each_line do |line|
      buffer << line
    end
    return buffer
  end
end
