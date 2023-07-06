# frozen_string_literal: true

class Suma::AnonProxy::MessageHandler::Fake < Suma::AnonProxy::MessageHandler
  class << self
    def handled = @handled ||= []

    attr_accessor :handle_callback, :can_handle_callback

    def reset
      self.handled.clear
      self.handle_callback = nil
      self.can_handle_callback = nil
    end
  end

  def key = "fake-handler"

  def can_handle?(msg)
    return false if self.class.can_handle_callback.nil?
    return self.class.can_handle_callback[msg]
  end

  def handle(vendor_account_message)
    self.class.handled << vendor_account_message
    return nil if self.class.handle_callback.nil?
    return self.class.handle_callback[vendor_account_message]
  end
end
