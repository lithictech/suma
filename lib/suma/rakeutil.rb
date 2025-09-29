# frozen_string_literal: true

module Suma::Rakeutil
  module_function def readall_nonblock(io, chunk_size=4096)
    buffer = +""
    chunk = " " * chunk_size
    loop do
      io.read_nonblock(chunk_size, chunk)
      buffer << chunk
    rescue IO::WaitReadable
      return nil
    rescue EOFError
      return buffer
    end
  end
end
