# frozen_string_literal: true

module Suma::Mobility::TripImporter
  class Receipt < Suma::TypedStruct
    attr_accessor :trip,
                  :total,
                  :discount,
                  :image_url

    # @return [Array<LineItem>]
    attr_accessor :line_items

    def _defaults
      super.merge(
        line_items: [],
        trip: Suma::Mobility::Trip.new(
          begin_lat: 0, begin_lng: 0,
          end_lat: 0, end_lng: 0,
        ),
      )
    end

    def line_item(**kw) = LineItem.new(**kw)
  end

  class LineItem < Suma::TypedStruct
    # @return [Money]
    attr_accessor :amount
    # @return [String]
    attr_accessor :memo
    # @return [Money,nil]
    attr_accessor :per_minute
    # @return [Integer,nil]
    attr_accessor :minutes
  end

  def self.import(receipt:, logger:)
    # Set default options, which can be
    trip = receipt.trip
    trip.db.transaction(savepoint: true) do
      begin
        Suma::Mobility::Trip.import_trip(
          trip,
          cost: receipt.total,
          undiscounted_subtotal: receipt.discount + receipt.total,
        )
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

      charge = trip.charge
      receipt.line_items&.each do |li|
        charge.add_off_platform_line_item(
          amount: li.amount,
          memo: Suma::TranslatedText.create(all: li.memo),
        )
      end
    end
  end
end
