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

  def auth(*)
    contact = self.vendor_account.ensure_anonymous_contact(:email)
    self.class._auth
    Suma::AnonProxy::VendorAccountRegistration.find_or_create_or_find(
      account: self.vendor_account,
      external_program_id: contact.email,
    )
  end

  def needs_polling? = self.class.needs_polling
  def needs_linking?(*) = self.vendor_account.contact.nil?
end
