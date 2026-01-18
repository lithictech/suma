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

  # Return the contents of the filename given to the task.
  # This is meant to handle a lot of common use cases:
  #
  # - rake task filename
  # - rake task[filename]
  # - cat filename | rake task
  # - rake task redis://keyname-storing-text
  # - rake task https://url-to-fetch
  #
  # If no parameter can be figured out, return nil.
  module_function def readfile(params, paramname: :filename)
    # We can't test ARGF easily so we do the same sort of thing ourselves.
    stdin_pipe_or_ci = !$stdin.tty?
    maybe_has_filename = ARGV.length > 2 # default is [rake, <taskname>].

    fname_from_params = params[paramname]
    filename, io = nil
    if fname_from_params.blank? && maybe_has_filename
      filename = ARGV.last
    elsif fname_from_params.blank? && stdin_pipe_or_ci
      io = $stdin
    elsif fname_from_params.blank?
      nil
    else
      filename = fname_from_params
    end
    if io.nil?
      if filename.nil?
        # There is no filename passed for ARGF (just 'rake <task>'),
        # and no STDIN piped in (or STDIN is at EOF, since tty is false in CI),
        # return nil.
        return nil
      elsif filename.start_with?("redis://")
        redis_key = filename.delete_prefix("redis://")
        val = Sidekiq.redis { |c| c.get(redis_key) }
        raise "Redis key '#{redis_key}' key not set" if val.blank?
        io = StringIO.new(val)
      elsif filename.start_with?("http")
        io = Suma::Http.get(filename, logger: nil, timeout: nil).body
      elsif filename
        io = File.open(filename)
      end
    end
    got = readall(io)
    return nil if got == "" && io == $stdin
    return got
  end
end
