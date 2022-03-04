# frozen_string_literal: true

# Helpers for working with biz gem.
# In short, doing `schedule.time(1, :day).after(at)`
# gives incorrect results, so we need to work with lower level objects.
# See TimeCalculator for more info.
module Suma::Biztime
  def self.periods_between(biz, start_time, end_time)
    return biz.periods.after(start_time).timeline.until(end_time).to_a
  end

  # Add the given number of days after `at` by talking periods that it can use as business day
  # (end after `at`), and return the biz day.
  def self.add_days_to_time(periods, at, count)
    periods = periods.select { |period| period.end_time > at }
    # Days are 1 based, indices are 0 based (so 1 day is the next period, at index 0)
    days = count - 1
    raise "Need more biz periods for #{at}" if periods.length <= days
    return periods[days]
  end

  # Roll dates forward, such that if time.to_date falls on a non-business day, skip it.
  def self.roll_days(biz, time, days: 1)
    dates = biz.dates
    t = time
    while t += 1.day
      days -= 1 if dates.active?(t)
      break unless days.positive?
    end
    return t
  end
end
