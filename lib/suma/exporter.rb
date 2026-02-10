# frozen_string_literal: true

require "csv"

class Suma::Exporter
  attr_reader :as_of

  def initialize(dataset, as_of: Time.now)
    @dataset = dataset
    @as_of = as_of
  end

  # Return array of typles of header/converter pair.
  # Converters take the row as the argument and return a stringable value.
  def headers = raise NotImplementedError

  def to_csv
    hd = self.headers
    coercers = hd.map(&:second)
    got = CSV.generate do |csv|
      csv << hd.map(&:first)
      @dataset.paged_each do |m|
        row = coercers.map do |c|
          v = c[m]
          # If the string starts with an equal sign, add 'UNSAFE' before it,
          # so spreadsheet programs will not evaluate it as a macro
          # which can be confusing (name of "=1+1" would appear as "2")
          # and potentially dangerous. A space or tab char is not enough
          # to prevent macros for some csv software like Numbers app on mac.
          v = "UNSAFE#{v}" if v.is_a?(String) && v.match?(/^\s*=/)
          v
        end
        csv << row
      end
    end
    return got
  end

  class Placeholder < Suma::Exporter
    def headers
      [
        ["Id", lambda(&:pk)],
        ["Note", ->(*) { "Placeholder exporter, ask devs to add support" }],
      ]
    end
  end
end
