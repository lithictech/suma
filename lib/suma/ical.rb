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

    # Create an event and return all projections.
    def project(dtstart, dtend, rrule, enum: :all_occurrences)
      ev = self.event(dtstart, dtend, rrule)
      occ = ev.send(enum)
      result = self.combine_occurrences(occ)
      return result
    end

    # Extract [start, end) pairs — Postgres tstzrange defaults to inclusive-start,
    # exclusive-end, so treat dtend as exclusive to match that normalization behavior.
    def combine_occurrences(occurrences)
      intervals = occurrences.
        map { |e| [e.start_time, e.end_time, e.parent] }.
        sort_by(&:first)

      merged = []
      intervals.each do |start, finish, parent|
        if merged.empty?
          merged << [start, finish, parent]
          next
        end

        last_start, last_finish, last_parent = merged.last
        # Overlapping or exactly adjacent ([a,b) + [b,c) => [a,c)) - merge.
        if start <= last_finish
          merged[-1] = [last_start, [last_finish, finish].max, last_parent]
        else
          merged << [start, finish, parent]
        end
      end
      return merged.map { |r| Icalendar::Recurrence::Occurrence.new(*r) }
    end
  end
end
