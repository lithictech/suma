# frozen_string_literal: true

class Suma::AnonProxy::AuthToVendor::Fake < Suma::AnonProxy::AuthToVendor
  class << self
    attr_accessor :calls

    def reset
      self.calls = 0
    end
  end

  def initialize(*)
    super
  end

  def auth
    self.class.calls ||= 0
    self.class.calls += 1
  end
end
