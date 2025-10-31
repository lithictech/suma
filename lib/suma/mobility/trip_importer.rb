# frozen_string_literal: true

# Importing a receipt is really annoying because everything is broken.
#
# The +Receipt+ type gives us the ability to parse a source of trips
# into a very precise format, so nothing is left to the imagination;
# and then it's recomposed back into Suma objects.
#
# Most use of the importers involve multiple different 'levels' of amounts:
# - The 'undiscounted subtotal', which is the full retail price of the trip.
#   It is often not in the receipt, so needs to be calculated by the undiscounted service rate
#   (plus additional line items!).
# - The 'unlock fee'. This may be in the receipt, or may be calculated by the primary service rate.
# - The 'per minute fee'. The cost per minute may be in the receipt,
#   or may be calculated by the primary service rate.
#   It is multipled by the trip duration minutes to get the total for this charge.
# - The 'misc line items'. These are usually parking or out-of-dock fees.
# - The 'paid off platofrm amount'. If the vendor charged the user through its own system,
#   this is the amount. We aren't charging the user if they already paid the vendor.
# - The 'subsizied by suma amount'. If suma has set up
module Suma::Mobility::TripImporter
  class Receipt
    # When the external service created the trip receipt/charge.
    # This also becomes the book transaction time.
    # @return [Time]
    attr_accessor :charged_at

    # The trip to be imported.
    # @return [Suma::Mobility::Trip]
    attr_reader :trip

    # The full retail price of the trip, including the undiscounted price of all line items.
    # @return [Money]
    attr_accessor :undiscounted_subtotal

    # The cost to unlock. The surcharge of the service rate.
    # @return [Money]
    attr_accessor :unlock_fee

    # The per-minute cost. The unit cost of the service rate.
    # @return [Money]
    attr_accessor :per_minute_fee

    # Line items to include in the charged amount.
    # Do NOT include unlock and ride fee items.
    # @return [Array<Suma::Mobility::EndTripResult::LineItem>]
    attr_reader :misc_line_items

    # If an image is available, it is fetched from this URL.
    attr_accessor :image_url

    # The amount the user paid for this trip off-platform (like for Biketown).
    #
    # If the total of the line items, minus the amount paid off-platform,
    # is what the member is charged.
    #
    # Note that charges to a member follow the normal suma ledger debit calculations
    # (ie, pulling from available ledgers before charging cash money).
    # @return [Money]
    attr_accessor :paid_off_platform_amount

    # The amount Suma paid the vendor to subsidize this trip.
    #
    # usually this means Suma will be invoiced by the vendor for this amount.
    # Note that this is *not* the amount Suma is
    # It may be zero if the ride is discounted by the vendor (often through a low-income program),
    # and the remainder is charged to the user (no additional suma discount).
    # @return [Money]
    attr_accessor :subsidized_off_platform_amount

    def initialize
      @trip = Suma::Mobility::Trip.new(
        begin_lat: 0, begin_lng: 0,
        end_lat: 0, end_lng: 0,
      )
      @misc_line_items = []
    end

    def end_trip_result
      r = Suma::Mobility::EndTripResult.new(
        undiscounted_cost: self.undiscounted_subtotal,
        charged_off_platform: self.paid_off_platform_amount,
        charge_at: self.charged_at,
        line_items: [],
      )
      unless self.unlock_fee.nil?
        r.line_items << Suma::Mobility::EndTripResult::LineItem.new(
          amount: self.unlock_fee,
          memo: "Unlock fee",
        )
      end
      unless self.per_minute_fee.nil?
        r.line_items << Suma::Mobility::EndTripResult::LineItem.new(
          amount: self.per_minute_fee * self.trip.duration_minutes,
          memo: "Riding - #{self.per_minute_fee.format}/min (#{trip.duration_minutes} min)",
        )
      end
      r.line_items.concat(self.misc_line_items)
      return r
    end
  end

  # Return the vendor service category used for fallback subsidies,
  # where no payment trigger applies but we need to create a subsidy.
  # We originate subsidies from a dedicated 'uncategorized' category/ledger
  # under whatever category the actual service uses.
  def self.create_fallback_subsidy_category(cat)
    return Suma.cached_get("trip-importer-fallback-category-#{cat.id}") do
      slug = "uncategorized_subsidy_#{cat.slug}"
      child = Suma::Vendor::ServiceCategory.find_or_create(slug:) do |sc|
        sc.parent = cat
        sc.name = "Uncategorized Subsidy for #{cat.name}"
      end
      child
    end
  end

  # @param receipt [Receipt]
  def self.import(receipt:, program:, logger:)
    trip = receipt.trip
    end_trip_result = receipt.end_trip_result
    trip.db.transaction do
      self._prepare_subsidy(receipt, program)
      begin
        trip.charge_trip(end_trip_result)
      rescue Sequel::UniqueConstraintViolation
        logger.debug("ride_already_exists", external_trip_id: trip.external_trip_id)
        raise Sequel::Rollback
      end
      if receipt.image_url
        resp = Suma::Http.get(receipt.image_url, logger:)
        map_uf = Suma::UploadedFile.create_with_blob(
          bytes: resp.body,
          content_type: resp.headers["Content-Type"],
          private: true,
          created_by: trip.member,
        )
        Suma::Image.create(
          mobility_trip: trip,
          uploaded_file: map_uf,
          caption: Suma::TranslatedText.empty,
        )
      end
    end
  end

  # Before charging the trip, if there was an explicit subsidy charged by the vendor to suma,
  # we need to add that money to the user ledger, so it can be used to pay for the trip.
  #
  # We use first 'potential' trigger; this logic is different from calculating ideal triggers,
  # since we already know the subsidized amount, and we can't realistically
  # 'back into' the right subsidy numbers based on how much we subsidized
  # (we only do this to find subsidy based on how much we paid).
  #
  # If there are no potential triggers, we fall back to creating a subsidy from a fallback ledger,
  # without a trigger, since we MUST have a subsidy of the right amount
  # to avoid charging the member. See code comments for explanation.
  #
  # We prefer triggers because this allows more precise control of ledgers,
  # and also shows predictive ride pricing properly.
  #
  # @param receipt [Receipt]
  def self._prepare_subsidy(receipt, _program)
    return if receipt.subsidized_off_platform_amount.zero?
    member_account = receipt.trip.member.payment_account!
    subsidizing_trigger = Suma::Payment::Trigger.
      gather(member_account, active_as_of: receipt.charged_at).
      potentially_contributing_to(receipt.trip.vendor_service).
      first
    if subsidizing_trigger
      subsidizing_trigger.execute(
        apply_at: receipt.charged_at,
        amount: receipt.subsidized_off_platform_amount,
        receiving_ledger: subsidizing_trigger.ensure_receiving_ledger(member_account),
      )
      return
    end

    # We know that the service has a category at this point (or we'd have already errored).
    # When we pay, charging the trip moves money from a ledger member which can pay for the service,
    # to a corresponding platform ledger.
    # However, we want to always send the fallback from a special "subsidy" category ledger
    # so we can easily keep track of what was categorized.
    # We don't want to create a corresponding member for the ledger,
    # both because it looks bad, and also because as a sub-category,
    # it can't be used to pay for the parent.
    # So, we create an extra transaction from the platform 'base' ledger (say, "mobility")
    # to a platform subsidy ledger ("fallback - mobility").
    # This sets 'mobility' negative and 'fallback - mobility' positive.
    # Then we create a transaction from the platform 'fallback - mobility' ledger,
    # to the member's 'mobility' ledger.
    # So when this fallback logic runs:
    # - platform 'mobility' is negative.
    # - platform 'fallback - mobility' is zero.
    # - member 'mobility' is positive.
    # When we pay for the trip, money is moved from member to platform 'mobility',
    # and everything is zero.
    fallback_cat = self.create_fallback_subsidy_category(receipt.trip.vendor_service.categories.first)
    parent_cat = fallback_cat.parent
    platform_fallback = Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(fallback_cat)
    platform_parent = Suma::Payment::Account.lookup_platform_vendor_service_category_ledger(parent_cat)
    member_parent = receipt.trip.member.payment_account.ensure_ledger_with_category(parent_cat)
    Suma::Payment::BookTransaction.create(
      apply_at: receipt.charged_at,
      amount: receipt.subsidized_off_platform_amount,
      originating_ledger: platform_parent,
      receiving_ledger: platform_fallback,
      memo: Suma::TranslatedText.create(all: "Rebalancing uncategorized subsidy"),
    )
    Suma::Payment::BookTransaction.create(
      apply_at: receipt.charged_at,
      amount: receipt.subsidized_off_platform_amount,
      originating_ledger: platform_fallback,
      receiving_ledger: member_parent,
      memo: Suma::TranslatedText.create(all: "Subsidy from local funders"),
    )
    Sentry.capture_message("Trip had off platform subsidy but no Payment Triggers") do |scope|
      scope.set_extras(
        external_trip_id: receipt.trip.external_trip_id,
        member_id: receipt.trip.member_id,
        member_name: receipt.trip.member.name,
        vendor_service_id: receipt.trip.vendor_service.id,
        vendor_service_name: receipt.trip.vendor_service.internal_name,
      )
    end
  end
end
