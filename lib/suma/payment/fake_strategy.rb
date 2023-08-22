# frozen_string_literal: true

require "suma/postgres/model"
require "suma/payment/funding_transaction/strategy"

class Suma::Payment::FakeStrategy < Suma::Postgres::Model(:payment_fake_strategies)
  include Suma::Payment::FundingTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"

  def initialize(*)
    @memory_responses = {}
    super
    self[:responses] ||= Sequel.pg_json({})
  end

  def short_name
    return "Fake"
  end

  [
    :originating_instrument,
    :check_validity,
    :ready_to_collect_funds?,
    :collect_funds,
    :funds_cleared?,
    :ready_to_send_funds?,
    :send_funds,
    :funds_settled?,
  ].each do |m|
    define_method(m) do |*args|
      self.return_response(m, *args)
    end
  end

  protected def return_response(symbol, *args)
    if @memory_responses&.key?(symbol)
      v = @memory_responses[symbol]
      raise v if v.is_a?(Exception)
      return v
    end
    syms = symbol.to_s
    if syms.end_with?("=")
      self.set_response(syms[..-2].to_sym, args[0])
      return args[0]
    end
    raise ArgumentError, "no response registered for #{symbol.inspect}" unless self.responses.key?(syms)
    result = self.responses[syms]
    if result.is_a?(Hash) && result.key?("klass")
      cls = result["klass"].constantize
      return cls[result.fetch("id")]
    end
    return result
  end

  def set_response(symbol, result)
    @memory_responses ||= {}
    @memory_responses[symbol] = result
    result = {"id" => result.id, "klass" => result.class.name} if
      result.is_a?(Suma::Postgres::Model)
    self.responses = self.responses.merge(symbol.to_s => result)
    self.save_changes
    return self
  end

  def not_ready
    return self.set_response(:check_validity, []).
        set_response(:ready_to_collect_funds?, false).
        set_response(:ready_to_send_funds?, false)
  end
end

# Table: payment_fake_strategies
# ----------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id        | integer | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  responses | jsonb   | NOT NULL DEFAULT '{}'::jsonb
# Indexes:
#  payment_fake_strategies_pkey | PRIMARY KEY btree (id)
# Referenced By:
#  payment_funding_transactions | payment_funding_transactions_fake_strategy_id_fkey | (fake_strategy_id) REFERENCES payment_fake_strategies(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------
