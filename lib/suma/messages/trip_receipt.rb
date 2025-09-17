# frozen_string_literal: true

require "suma/message/template"

class Suma::Messages::TripReceipt < Suma::Message::Template
  def self.fixtured(recipient)
    trip = Suma::Fixtures.mobility_trip.ended.create(member: recipient)
    tmpl = self.new(trip)
    Suma::Fixtures.static_string.
      message(tmpl, "sms").
      text("test receipt (en)", es: "test receipt (es)").
      create
    return tmpl
  end

  def initialize(trip)
    @trip = trip
    super()
  end

  def template_folder = "mobility"
  def localized? = true

  def liquid_drops
    return super.merge(
      minutes: @trip.duration_minutes,
      vendor_name: @trip.vendor_service.vendor.name,
      trip_link: "#{Suma.app_url}/#{@trip.rel_app_link}",
    )
  end
end
