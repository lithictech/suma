# frozen_string_literal: true

class Suma::Message::Carrier::Noop < Suma::Message::Carrier
  def name = "noop"

  def send!(delivery_id:)
    return "noop-#{delivery_id}-#{SecureRandom.hex(6)}"
  end
end
