# frozen_string_literal: true

require "amigo/job"

# Whenever a category is created, ensure there is a platform ledger for it.
# This is a pretty simple approach that should be good enough
# to ensure ledgers exist after a category is created,
# so we can for example create payment triggers.
class Suma::Async::LedgerCreateForCategory
  extend Amigo::Job

  on "suma.vendor.servicecategory.created"

  def _perform(event)
    o = self.lookup_model(Suma::Vendor::ServiceCategory, event)
    Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(o)
  end
end
