# frozen_string_literal: true

class Suma::Payment::LedgersView
  attr_reader :ledgers
  attr_accessor :minimum_recent_lines

  def initialize(ledgers=[], member:, now: Time.now)
    @ledgers = ledgers
    @member = member
    @now = now
    @minimum_recent_lines = 10
  end

  def total_balance
    return self.ledgers.sum(Money.new(0), &:balance)
  end

  def lifetime_savings
    return @member.charges.sum(Money.new(0), &:discount_amount)
  end

  class RecentLine < Suma::TypedStruct
    attr_accessor :id, :amount, :apply_at, :memo, :opaque_id, :usage_details

    def directed? = true
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
    # Merge transactions with the same memo and apply_at.
    # There's no reason to split these up, since this view goes across all the member's ledgers;
    # they can't tell what goes to Cash vs. Food anyway.
    merged = {}
    lines.each do |bx|
      key = [bx.apply_at, bx.memo_id]
      if (recent_line = merged[key])
        recent_line.amount += bx.amount
      else
        merged[key] =
          RecentLine.new(
            id: bx.id,
            amount: bx.amount,
            apply_at: bx.apply_at,
            memo: bx.memo,
            opaque_id: bx.opaque_id,
            usage_details: bx.usage_details,
          )
      end
    end
    # Sort lines by recency, then within the same instant:
    # - Negative values first
    # - Higher absolute amounts on top of lower amounts
    # - Use memo id as a tiebreaker
    # So you get an ordering like: -$24, $19, $5.
    new_lines = merged.values.sort do |rl1, rl2|
      next 1 if rl1.apply_at < rl2.apply_at
      next -1 if rl1.apply_at > rl2.apply_at
      next -1 if rl1.amount.negative? && !rl2.amount.negative?
      next 1 if !rl1.amount.negative? && rl2.amount.negative?
      rl1amtabs = rl1.amount.to_f.abs
      rl2amtabs = rl2.amount.to_f.abs
      next -1 if rl1amtabs > rl2amtabs
      next 1 if rl1amtabs < rl2amtabs
      next -1 if rl1.memo.id < rl2.memo.id
      next 1 if rl1.memo.id > rl2.memo.id
      0
    end
    return new_lines
  end
end
