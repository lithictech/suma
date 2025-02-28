# frozen_string_literal: true

class Suma::AnonProxy::MessageHandler::Noop < Suma::AnonProxy::MessageHandler
  def key = "noop"

  def can_handle?(*) = false
end
