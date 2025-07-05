# frozen_string_literal: true

require "suma/postgres"
require "suma/anon_proxy"

# Registrations represent a vendor account's being registered or enrolled with specific programs
# within a vendor. This model is similar in concept for a program enrollment,
# except the 'program' concept is an external concept (the +external_program_id+).
class Suma::AnonProxy::VendorAccountRegistration < Suma::Postgres::Model(:anon_proxy_vendor_account_registrations)
  plugin :timestamps

  many_to_one :account, class: "Suma::AnonProxy::VendorAccount"

  # The account this registration belongs to.
  # @!attribute account
  # @return [Suma::AnonProxy::VendorAccount]

  # The ID this registration is associated with, like a Lyft Pass program ID.
  # @!attribute external_program_id
  # @return [String]

  # The ID in the vendor's system of this registration.
  # Usually used to remove the member from the vendor's program,
  # when the removal requires knowing something about the registration into the vendor's program.
  # @!attribute external_registration_id
  # @return [String]
end
