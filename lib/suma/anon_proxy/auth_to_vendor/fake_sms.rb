# frozen_string_literal: true

class Suma::AnonProxy::AuthToVendor::Fake < Suma::AnonProxy::AuthToVendor
  class << self
    attr_accessor :calls, :auth, :needs_polling, :needs_attention

    def reset
      self.calls = 0
      self.auth = nil
      self.needs_polling = nil
      self.needs_attention = nil
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

  def auth(*) = self.class._auth
  # TODO: create fake sms/email auth_to_vendors that create member contacts and vendor account registrations,
  # since those are pretty vital to this flow.
  # TODO: why is linking a vendor account now showing anything (probably bootstrap file needs updating?)
  def needs_polling? = self.class.needs_polling
  def needs_attention?(*) = self.class.needs_attention

  # TODO: Bootstrap should not refer to lime or lyft, it's way too confusing
end
