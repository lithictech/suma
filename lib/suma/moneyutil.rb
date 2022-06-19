# frozen_string_literal: true

class Suma::Moneyutil
  def self.divide(m, parts)
    base_cents, leftover = m.cents.divmod(parts)
    result = Array.new(parts) do |i|
      # If we divide evenly, leftover will be 0, otherwise it will contain the number of items
      # that will need an additional cent in order to cover the remainder.
      these_cents = base_cents
      (these_cents += 1) if i < leftover
      Money.new(these_cents, m.currency)
    end
    return result
  end

  def self.to_h(m)
    return {currency: m.currency.iso_code, cents: m.cents}
  end
end
