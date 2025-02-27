# frozen_string_literal: true

class Suma::AnonProxy::AuthToVendor::Fake < Suma::AnonProxy::AuthToVendor
  class << self
    attr_accessor :calls, :auth, :needs_polling

    def reset
      self.calls = 0
      self.auth = nil
      self.needs_polling = nil
    end

    def _auth
      self.calls ||= 0
      self.calls += 1
      self.auth&.call
    end
  end

  def initialize(*)
    super
  end

  def auth = self.class._auth
  def needs_polling? = self.class.needs_polling
end
