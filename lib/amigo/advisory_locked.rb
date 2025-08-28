# frozen_string_literal: true

require "sequel/advisory_lock"

# Allows jobs to operate with an advisory lock,
# and retry or give up if the lock is taken.
# Register the +ServerMiddleware+,
# and pass :advisory_lock to +sidekiq_options+ to activate.
#
# Supported options:
#
# - +:db+: Required. Connect to this +Sequel::Database+. Can also be a callable that returns the database.
# - +:key+: Advisory lock bigint key. By default, hash the class name.
# - +:backoff+: If the advisory lock is taken, when to retry again. Default to 1 minute. Use nil to not retry.
module Amigo::AdvisoryLocked
  def self.string_to_int64(s)
    # "q>" grabs the first 8 bytes (of a digest/hash- for example MD5 is 128 bits, or 16 bytes)
    # as a signed 64 bit integer. The first 8 bytes is enough entropy.
    return Digest::MD5.digest(s).unpack1("q>")
  end

  def self.advisory_lock_options(cls)
    opts = cls.get_sidekiq_options.fetch("advisory_lock", nil)
    return nil if opts.nil?
    if (db = opts["db"]) && !db.is_a?(Sequel::Database)
      opts["db"] = db.call
    end
    opts["key"] ||= Amigo::AdvisoryLocked.string_to_int64(cls.name)
    opts["backoff"] = 1.minutes unless opts.key?("backoff")
    return opts
  end

  def self.advisory_lock(worker, db: nil)
    opts = Amigo::AdvisoryLocked.advisory_lock_options(worker)
    return nil if opts.nil?
    return Sequel::AdvisoryLock.new(db || opts.fetch("db"), opts.fetch("key"))
  end

  class ServerMiddleware
    def call(worker, job, _queue, &)
      alock = Amigo::AdvisoryLocked.advisory_lock(worker.class)
      return yield if alock.nil?
      performed, _ = alock.with_lock?(&)
      return if performed
      backoff = Amigo::AdvisoryLocked.advisory_lock_options(worker.class).fetch("backoff")
      worker.class.perform_in(backoff, *job.fetch("args")) if backoff
    end
  end
end
