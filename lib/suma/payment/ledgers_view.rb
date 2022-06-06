# frozen_string_literal: true

class Suma::Payment::LedgersView
  attr_reader :ledgers

  def initialize(ledgers, now: Time.now)
    @ledgers = ledgers || []
    @now = now
  end

  def total_balance
    return self.ledgers.sum(Money.new(0), &:balance)
  end

  def recent_lines
    recent = @now - 60.days
    lines = []
    [:received_book_transactions_dataset, :originated_book_transactions_dataset].each do |dsmethod|
      lines.concat(self.ledgers.map do |ledger|
        ledger.send(dsmethod).where { apply_at > recent }.all.map { |bt| bt.directed(ledger) }
      end.flatten)
    end
    lines = lines.sort_by(&:apply_at).reverse
    return lines
  end
end
