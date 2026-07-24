# frozen_string_literal: true

require "suma/ical"

RSpec.describe Suma::Ical do
  it "can create aa vevent string" do
    expect(described_class.event_str(Time.at(1), Time.at(2), "")).to eq(
      "BEGIN:VEVENT\nDTSTART:19700101T000001Z\nDTEND:19700101T000002Z\nEND:VEVENT",
    )
    expect(described_class.event_str(Time.at(1), Time.at(2), "COUNT=1")).to eq(
      "BEGIN:VEVENT\nDTSTART:19700101T000001Z\nDTEND:19700101T000002Z\nRRULE:COUNT=1\nEND:VEVENT",
    )
  end

  it "can create a vevent" do
    expect(described_class.event(Time.at(1), Time.at(2), "")).to have_attributes(
      dtstart: match_time(Time.at(1)), rrule: [],
    )
    expect(described_class.event(Time.at(1), Time.at(2), "COUNT=1")).to have_attributes(rrule: have_length(1))
  end

  describe "combine_occurrences" do
    let(:occ) { Icalendar::Recurrence::Occurrence }

    def t(str) = Time.parse(str)
    def occurrence(start_str, end_str) = occ.new(t(start_str), t(end_str))

    it "returns an empty array when given no events" do
      expect(described_class.combine_occurrences([])).to eq([])
    end

    it "returns a single interval for a single event" do
      occurrences = [occurrence("2026-01-01 10:00", "2026-01-01 11:00")]
      result = described_class.combine_occurrences(occurrences)
      expect(result).to eq([occurrence("2026-01-01 10:00", "2026-01-01 11:00")])
    end

    it "keeps disjoint, non-overlapping occurrences separate" do
      occurrences = [
        occurrence("2026-01-01 10:00", "2026-01-01 11:00"),
        occurrence("2026-01-01 12:00", "2026-01-01 13:00"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result).to eq([
                             occurrence("2026-01-01 10:00", "2026-01-01 11:00"),
                             occurrence("2026-01-01 12:00", "2026-01-01 13:00"),
                           ])
    end

    it "merges two overlapping occurrences into one interval" do
      occurrences = [
        occurrence("2026-01-01 10:00", "2026-01-01 11:30"),
        occurrence("2026-01-01 11:00", "2026-01-01 12:00"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result).to eq([occurrence("2026-01-01 10:00", "2026-01-01 12:00")])
    end

    it "merges exactly-adjacent occurrences (end of one == start of next)" do
      occurrences = [
        occurrence("2026-01-01 10:00", "2026-01-01 11:00"),
        occurrence("2026-01-01 11:00", "2026-01-01 12:00"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result).to eq([occurrence("2026-01-01 10:00", "2026-01-01 12:00")])
    end

    it "merges a fully-contained event into its enclosing interval" do
      occurrences = [
        occurrence("2026-01-01 09:00", "2026-01-01 17:00"),
        occurrence("2026-01-01 10:00", "2026-01-01 11:00"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result).to eq([occurrence("2026-01-01 09:00", "2026-01-01 17:00")])
    end

    it "does not shrink the merged end time when a later interval ends earlier" do
      # merged.last should take the max of the two ends, not just overwrite it
      occurrences = [
        occurrence("2026-01-01 09:00", "2026-01-01 17:00"),
        occurrence("2026-01-01 16:00", "2026-01-01 16:30"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result).to eq([occurrence("2026-01-01 09:00", "2026-01-01 17:00")])
    end

    it "chains merges across more than two overlapping occurrences" do
      occurrences = [
        occurrence("2026-01-01 10:00", "2026-01-01 11:00"),
        occurrence("2026-01-01 10:30", "2026-01-01 12:00"),
        occurrence("2026-01-01 11:45", "2026-01-01 13:00"),
      ]
      result = described_class.combine_occurrences(occurrences)
      expect(result).to eq([occurrence("2026-01-01 10:00", "2026-01-01 13:00")])
    end

    it "produces the same result regardless of input order" do
      occurrences = [
        occurrence("2026-01-01 12:00", "2026-01-01 13:00"),
        occurrence("2026-01-01 10:00", "2026-01-01 11:30"),
        occurrence("2026-01-01 11:00", "2026-01-01 12:30"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result).to eq([occurrence("2026-01-01 10:00", "2026-01-01 13:00")])
    end

    it "keeps two occurrences separate when there is a gap, even a small one" do
      occurrences = [
        occurrence("2026-01-01 10:00", "2026-01-01 11:00"),
        occurrence("2026-01-01 11:00:01", "2026-01-01 12:00"),
      ]

      result = described_class.combine_occurrences(occurrences)

      expect(result.length).to eq(2)
    end

    it "handles multiple separate merged clusters" do
      occurrences = [
        occurrence("2026-01-01 09:00", "2026-01-01 10:00"),
        occurrence("2026-01-01 09:30", "2026-01-01 10:30"),
        occurrence("2026-01-02 09:00", "2026-01-02 10:00"),
        occurrence("2026-01-02 09:45", "2026-01-02 11:00"),
      ]

      result = described_class.combine_occurrences(occurrences)
      expect(result).to eq([
                             occurrence("2026-01-01 09:00", "2026-01-01 10:30"),
                             occurrence("2026-01-02 09:00", "2026-01-02 11:00"),
                           ])
    end
  end
end
