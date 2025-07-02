# frozen_string_literal: true

require "suma/simple_registry"

class Suma::AnonProxy::AuthToVendor
  extend Suma::SimpleRegistry

  require_relative "auth_to_vendor/fake"
  register(:fake, Fake)

  require_relative "auth_to_vendor/lime"
  register(:lime, Lime)

  require_relative "auth_to_vendor/lyft_pass"
  register(:lyft_pass, LyftPass)

  # @return [Suma::AnonProxy::Provision]
  def self.create!(key, vendor_account:)
    return self.registry_create!(key, vendor_account)
  end

  # @return [Suma::AnonProxy::VendorAccount]
  attr_reader :vendor_account

  def initialize(vendor_account)
    @vendor_account = vendor_account
  end

  # Run the auth in the vendor system (send magic link email, associate the Suma member with the vendor backend, etc.)
  def auth(now:) = raise NotImplementedError

  # True if the client should poll for an access code set on the vendor account,
  # or false if the linking is immediate.
  # @return [true,false]
  def needs_polling? = raise NotImplementedError

  # True if the vendor account needs attention; like if it needs to be created
  # or relinked.
  def needs_attention?(now:) = raise NotImplementedError
end
