# frozen_string_literal: true

require "icalendar"
require "icalendar/recurrence"

module Suma::Ical
  class << self
    # Return a VEVENT string including fields which are set.
    # If tags is true, include BEGIN/END tags.
    # @param [Time] dtstart
    # @param [Time] dtend
    # @param [String] rrule
    # @return [String]
    def event_str(dtstart, dtend, rrule, tags: true)
      return [
        tags ? "BEGIN:VEVENT" : nil,
        dtstart ? "DTSTART:#{_icaltime(dtstart)}" : nil,
        dtend ? "DTEND:#{_icaltime(dtend)}" : nil,
        rrule.present? ? "RRULE:#{rrule}" : nil,
        tags ? "END:VEVENT" : nil,
      ].compact.join("\n")
    end

    # @param [Time] t
    # @return [String]
    def _icaltime(t) = t.utc.strftime("%Y%m%dT%H%M%SZ")

    # @param [Time] dtstart
    # @param [Time] dtend
    # @param [String] rrule
    # @return [Icalendar::Event]
    def event(dtstart, dtend, rrule)
      event = Icalendar::Event.new
      event.dtstart = Icalendar::Values::DateTime.new(dtstart)
      event.dtend = Icalendar::Values::DateTime.new(dtend)
      event.rrule = Icalendar::Values::Recur.new(rrule) if rrule.present?
      return event
    end
  end
end
