# frozen_string_literal: true

require "suma/postgres/model"

# Support idempotent operations.
# This is very useful when
# 1) protecting the API against requests dispatched multiple times,
# as browsers are liable to do, and
# 2) designing parts of a system so they can be used idempotently, especially async jobs.
# This ensures an event can be republished if a job fails, but jobs that worked won't be re-run.
#
# In general, you do not use Idempotency instances directly;
# instead, you will use once_ever and every.
# For example, to only send a welcome email once:
#
#   Suma::Idempotency.once_ever.under_key("welcome-email-#{customer.id}") { send_welcome_email(customer) }
#
# Similarly, to prevent an action email from going out multiple times in a short period accidentally:
#
#   Suma::Idempotency.every(1.hour).under_key("new-order-#{order.id}") { send_new_order_email(order) }
#
# Note that idempotency cannot be executed while already in a transaction.
# If it were, the unique row would not be visible to other transactions.
# So the new row must be committed, then the idempotency evaluated (and the callback potentially run).
# To disable this check, set 'Postgres.unsafe_skip_transaction_check' to true,
# usually using the :no_transaction_check spec metadata.
#
class Suma::Idempotency < Suma::Postgres::Model(:idempotencies)
  extend Suma::MethodUtilities

  NOOP = :skipped

  # Skip the transaction check. Useful in unit tests. See class docs for details.
  singleton_predicate_accessor :skip_transaction_check

  def self.once_ever
    idem = self.new
    idem.__once_ever = true
    return idem
  end

  def self.every(interval)
    idem = self.new
    idem.__every = interval
    return idem
  end

  attr_accessor :__every, :__once_ever

  def under_key(key, &block)
    self.key = key
    return self.execute(&block) if block
    return self
  end

  def transaction_ok(&block)
    @transaction_ok = true
    return self.execute(&block) if block
    return self
  end

  def execute
    unless @transaction_ok
      Suma::Postgres.check_transaction(
        self.db,
        "Cannot use idempotency while already in a transaction, since side effects may not be idempotent",
      )
    end

    self.class.dataset.insert_conflict.insert(key: self.key)
    self.db.transaction do
      idem = Suma::Idempotency[key: self.key].lock!
      if idem.last_run.nil?
        result = yield()
        idem.update(last_run: Time.now)
        return result
      end
      return NOOP if self.__once_ever
      return NOOP if Time.now < (idem.last_run + self.__every)
      result = yield()
      idem.update(last_run: Time.now)
      return result
    end
  end
end
