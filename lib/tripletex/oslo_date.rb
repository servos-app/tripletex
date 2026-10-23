module Tripletex
  # Tripletex keeps Oslo's clock. Plain Ruby has no time-zone database, so this applies Norway's rule, the EU's:
  # UTC+2 from 01:00 UTC on the last Sunday of March to 01:00 UTC on the last Sunday of October, UTC+1 otherwise.
  module OsloDate
    HOUR = 3600

    module_function

    def tomorrow(now) = today(now).next_day

    def today(now)
      utc = now.getutc
      (utc + utc_offset(utc)).to_date
    end

    def utc_offset(now)
      utc = now.getutc
      summer_time = switchover(utc.year, 3)...switchover(utc.year, 10)
      summer_time.cover?(utc) ? 2 * HOUR : HOUR
    end

    def switchover(year, month)
      last_day = Date.new(year, month, -1)
      Time.utc(year, month, last_day.day - last_day.wday, 1)
    end
  end
end
