# frozen_string_literal: true

# Importing a receipt is really annoying because everything is broken.
#
# The +Receipt+ type gives us the ability to parse a source of trips
# into a very precise format, so nothing is left to the imagination;
# and then it's recomposed back into Suma objects.
#
# Most use of the importers involve multiple different 'levels' of amounts:
# - The 'undiscounted subtotal', which is the retail value of the trip.
#   It is often not in the receipt, so needs to be calculated by the undiscounted service rate
#   (plus additional line items!).
# - The 'unlock fee'. This may be in the receipt, or may be calculated by the primary service rate.
# - The 'per minute fee'. The cost per minute may be in the receipt,
#   or may be calculated by the primary service rate.
#   It is multipled by the trip duration minutes to get the total for this charge.
# - The 'misc line items'. These are usually parking violations.
# - The 'paid off platofrm amount'. If the vendor charged the user, this is the amount.
# - The 'to charge member amount'. If the vendor doesn't charge the member, this is the amount suma charges them.
# - The 'subsizied by suma amount'. If the vendor is invoicing suma, this is the amount.
module Suma::Mobility::TripImporter
  class Receipt
    # When the external service created the trip receipt/charge.
    # This also becomes the book transaction time.
    # @return [Time]
    attr_accessor :charged_at

    # Controls what ledger the trip will be associated with.
    # Usually this is a child of the mobility ledger.
    # @return [Suma::Vendor::ServiceCategory]
    attr_accessor :category

    # The trip to be imported.
    # @return [Suma::Mobility::Trip]
    attr_reader :trip

    # These line items are added to the charge as 'self data' line items (informational only).
    # Do NOT include unlock and ride fee items.
    # @return [Array<LineItem>]
    attr_reader :misc_line_items

    # @return [Money]
    attr_accessor :undiscounted_subtotal

    # The cost to unlock. The surcharge of the service rate.
    # @return [Money]
    attr_accessor :unlock_fee

    # The per-minute cost. The unit cost of the service rate.
    # @return [Money]
    attr_accessor :per_minute_fee

    # If an image is available, it is fetched from this URL.
    attr_accessor :image_url

    # The amount to charge the member.
    # If +paid_off_platform+ is nonzero,
    # +to_charge_member+ is normally zero.
    # Both fields may be zero if the trip was fully paid by the vendor.
    # Note that charges to a member follow the normal suma ledger debit calculations
    # (ie, pulling from available ledgers before charging cash money).
    # @return [Money]
    attr_accessor :to_charge_member_amount

    # The amount the user paid for this trip off-platform.
    # See +to_charge_member+ for more info.
    # @return [Money]
    attr_accessor :paid_off_platform_amount

    # The amount Suma paid the vendor to subsidize this trip;
    # usually this means Suma will be invoiced by the vendor
    # for this amount.
    # It may be zero if the ride is discounted by the vendor (often through a low-income program),
    # and the remainder is charged to the user (no additional suma discount).
    # @return [Money]
    attr_accessor :subsidized_by_suma_amount

    def initialize
      @trip = Suma::Mobility::Trip.new(
        begin_lat: 0, begin_lng: 0,
        end_lat: 0, end_lng: 0,
      )
      @misc_line_items = []
    end
  end

  class LineItem < Suma::TypedStruct
    # @return [Money]
    attr_accessor :amount
    # @return [String]
    attr_accessor :memo
  end

  # @param receipt [Receipt]
  def self.import(receipt:, program:, logger:)
    trip = receipt.trip
    trip.db.transaction(savepoint: true) do
      begin
        charge = Suma::Mobility::Trip.import_trip(
          trip,
          cost: receipt.to_charge_member_amount,
          undiscounted_subtotal: receipt.undiscounted_subtotal,
        )
      rescue Sequel::UniqueConstraintViolation
        logger.debug("ride_already_exists", external_trip_id: trip.external_trip_id)
        raise Sequel::Rollback
      end
      if charge.nil?
        # TODO: test
        return
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

      # Once we've "imported" the trip, we have a trip,
      # a charge (for "to_charge_member_amount"), and no line items.
      #
      charge = trip.charge
      charge.add_off_platform_line_item(
        amount: receipt.unlock_fee,
        memo: Suma::TranslatedText.create(all: "Unlock fee"),
      )
      charge.add_off_platform_line_item(
        amount: receipt.per_minute_fee * trip.duration_minutes,
        memo: Suma::TranslatedText.create(
          all: "Riding - #{receipt.per_minute_fee.format}/min (#{trip.duration_minutes} min)",
        ),
      )
      receipt.misc_line_items.each do |li|
        charge.add_off_platform_line_item(
          amount: li.amount,
          memo: Suma::TranslatedText.create(all: li.memo),
        )
      end
      if receipt.subsidized_by_suma_amount.nonzero?
        # If there is a subsidy, we need to figure out how to apply it.
        # Our best guess of how this should work, is that we find a payment trigger
        # for the program the trip was taken with, and try to create a subsidy from this trigger.
        #
        # This follows a different code path from payment triggers during commerce checkout,
        # since the situation is pretty different: this charge is coming after-the-fact,
        # and we don't have great control over how its categories are set up
        # (so the trigger subsidy matching cannot be relied on fully).
        #
        # So instead of gathering all applicable triggers (across all programs),
        # we gather only mobility triggers for a given program.
        #
        # It is likely this logic will all change in the future.
        trigger_collection = Suma::Payment::Trigger.gather(
          trip.member.payment_account!,
          active_as_of: apply_at,
          dataset: Suma::Payment::Trigger.where(programs: [program]),
        )
        calc_ctx = Suma::Payment::CalculationContext.new(apply_at)
        funding_plan = trigger_collection.funding_plan(calc_ctx, receipt.subsidized_by_suma_amount)
        # Since we don't have 'outside' categories (like those set up from products),
        # use the ledger the trigger itself creates/wants to send to.
        member_ledger = Suma::Enumerable.one!(funding_plan.steps).receiving_ledger
        executions = funding_plan.execute(ledgers: [member_ledger], at: apply_at)
        executions.each do |execution|
          charge.add_line_item(book_transaction: execution.book_transaction)
        end
      end
    end
  end
end
