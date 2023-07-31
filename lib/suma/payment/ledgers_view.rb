# frozen_string_literal: true

class Suma::Payment::LedgersView
  attr_reader :ledgers
  attr_accessor :minimum_recent_lines

  def initialize(ledgers, now: Time.now)
    @ledgers = ledgers || []
    @now = now
    @minimum_recent_lines = 10
  end

  def total_balance
    return self.ledgers.sum(Money.new(0), &:balance)
  end

  def recent_lines
    recent = @now - 60.days
    lines = []
    [:received_book_transactions_dataset, :originated_book_transactions_dataset].each do |dsmethod|
      lines.concat(self.ledgers.map do |ledger|
        ledger.send(dsmethod).
          where { apply_at > recent }.
          all.
          map { |bt| bt.directed(ledger) }
      end.flatten)
    end
    remainder_to_show = self.minimum_recent_lines - lines.length

    if remainder_to_show.positive?
      [:received_book_transactions_dataset, :originated_book_transactions_dataset].each do |dsmethod|
        lines.concat(self.ledgers.map do |ledger|
          # Same as above, except grab a limited set of older transactions.
          ledger.send(dsmethod).
            where { apply_at <= recent }.
            limit(remainder_to_show).
            all.
            map { |bt| bt.directed(ledger) }
        end.flatten)
      end
      # We can end up with extra transactions, since we LIMIT and add multiple sets.
      # Ensure we end up with a consistent amount.
      lines = lines.take(self.minimum_recent_lines)
    end
    lines = lines.sort_by(&:apply_at).reverse
    return lines
  end
end
