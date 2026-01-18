# frozen_string_literal: true

require "io/wait"

module Suma::Rakeutil
  module_function def readall_nonblock(io, chunk_size=4096)
    io = io.to_io

    buffer = +""
    chunk = " " * chunk_size
    begin
      loop do
        io.read_nonblock(chunk_size, chunk)
        buffer << chunk
      end
    rescue EOFError
      return buffer
    rescue IO::WaitReadable
      io.wait_readable(chunk_size)
      retry
    end
  end
end
