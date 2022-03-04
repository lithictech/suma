# frozen_string_literal: true

require "securerandom"

require "suma/postgres"
require "suma/customer"

class Suma::Customer::ResetCode < Suma::Postgres::Model(:customer_reset_codes)
  class Unusable < RuntimeError; end

  plugin :timestamps

  many_to_one :customer, class: Suma::Customer

  dataset_module do
    def usable
      return self.where(Sequel[used: false] & Sequel.expr { expire_at > Sequel.function(:now) })
    end
  end

  # Invoke the given block with the reset code referred to by token.
  # Raise Unusable if code is unusable.
  def self.use_code_with_token(token)
    raise LocalJumpError unless block_given?

    code = self.usable[token:]
    raise Unusable unless code&.usable?

    code.db.transaction do
      code.use!
      yield(code)
    end
  end

  def initialize(*)
    super
    self.token ||= Array.new(6) { rand(0..9) }.join
    self.expire_at ||= 15.minutes.from_now
  end

  def expire!
    self.update(expire_at: Time.now)
    return self
  end

  def expired?
    return self.expire_at < Time.now
  end

  def use!
    now = Time.now
    self.customer.reset_codes_dataset.usable.update(expire_at: now)
    self.update(used: true, expire_at: now)
    return self
  end

  def verify
    self.customer.verify_phone if self.transport == "sms"
    self.customer.verify_email if self.transport == "email"
  end

  def used?
    return self.used
  end

  def usable?
    return false if self.used?
    return !self.expired?
  end

  #
  # :section: Sequel Validation
  #

  def validate
    super
    self.validates_includes(["sms", "email"], :transport)
  end
end
