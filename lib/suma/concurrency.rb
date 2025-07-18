# frozen_string_literal: true

module Suma::Concurrency
  # Write to a temp file and then move it to target_path.
  # This allows existing file handles to operate on the old version
  # and avoid any inconsistency or corruption.
  module_function def atomic_write(target_path, mode: "w")
    dir = File.dirname(target_path)
    Tempfile.create(File.basename(target_path), dir) do |tempfile|
      tempfile.binmode if mode.include?("b")
      tempfile.sync = true
      tempfile.set_encoding(Encoding::BINARY) if mode.include?("b")
      yield tempfile
      # Explicit close means the file won't be unlinked on GC
      tempfile.close
      FileUtils.mv(tempfile.path, target_path)
    end
  end
end
