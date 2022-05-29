# frozen_string_literal: true

require "suma/postgres/model"
require "suma/payment/funding_transaction/strategy"

class Suma::Payment::FakeStrategy < Suma::Postgres::Model(:payment_fake_strategies)
  include Suma::Payment::FundingTransaction::Strategy

  one_to_one :funding_transaction, class: "Suma::Payment::FundingTransaction"

  def initialize(*)
    @memory_responses = {}
    super
  end

  def short_name
    return "Fake"
  end

  [:ready_to_collect_funds?, :collect_funds, :funds_cleared?].each do |m|
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
    return self.responses[syms]
  end

  def set_response(symbol, result)
    @memory_responses ||= {}
    @memory_responses[symbol] = result
    self.responses = self.responses.merge(symbol.to_s => result)
    self.save_changes
  end
end
