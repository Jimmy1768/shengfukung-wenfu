# app/helpers/scheduling/run_time.rb
require "zlib"

module Scheduling
  module RunTime
    # ---- Jitter helpers ---------------------------------------------------

    # Deterministic jitter offset in seconds in [0, jitter_minutes*60).
    # Uses a stable crc32 hash of (academy_id + optional salt) so each academy
    # consistently gets the same offset within the window.
    def self.jitter_offset_seconds(academy_id: nil, jitter_minutes: 15, salt: nil)
      jm = jitter_minutes.to_i
      raise ArgumentError, "jitter_minutes must be >= 0" if jm.negative?
      return 0 if jm.zero?

      base   = (salt || "jitter").to_s
      key    = academy_id.nil? ? base : "#{academy_id}-#{base}"
      bucket = Zlib.crc32(key) % jm
      bucket * 60
    end

    # Apply jitter to a UTC time.
    def self.apply_jitter_utc(time_utc, academy_id: nil, jitter_minutes: 15, salt: nil)
      return time_utc if jitter_minutes.to_i <= 0
      time_utc + jitter_offset_seconds(academy_id: academy_id, jitter_minutes: jitter_minutes, salt: salt)
    end

    # ---- Local time builders ----------------------------------------------

    # Build a UTC time for a specific *local* date (Date or "YYYY-MM-DD") at HH:MM.
    def self.local_time_on(tz, date, hhmm)
      zone_name = Scheduling::TimeZoneResolver.zone_name(tz)
      hour, min = hhmm.split(":").map(&:to_i)

      Time.use_zone(zone_name) do
        d = date.is_a?(Date) ? date : Date.parse(date.to_s)
        Time.zone.local(d.year, d.month, d.day, hour, min, 0).utc
      end
    end

    # Next daily occurrence of HH:MM in the given local tz (tomorrow if already passed).
    def self.next_local_time(tz, hhmm, from: nil)
      zone_name = Scheduling::TimeZoneResolver.zone_name(tz)
      hour, min = hhmm.split(":").map(&:to_i)

      Time.use_zone(zone_name) do
        now    = from ? from.in_time_zone(zone_name) : Time.zone.now
        target = now.change(hour: hour, min: min, sec: 0)
        target += 1.day if target <= now
        target.utc
      end
    end

    # Next weekly occurrence: weekday (0=Sun..6=Sat) at HH:MM in the local tz.
    def self.next_weekday_local_time(tz, hhmm, weekday, from: nil)
      zone_name = Scheduling::TimeZoneResolver.zone_name(tz)
      hour, min = hhmm.split(":").map(&:to_i)

      Time.use_zone(zone_name) do
        now        = from ? from.in_time_zone(zone_name) : Time.zone.now
        days_ahead = (weekday - now.wday) % 7
        target     = (now.to_date + days_ahead).to_time.change(hour: hour, min: min, sec: 0)
        target    += 7.days if target <= now
        target.utc
      end
    end

    # Next monthly occurrence: day_of_month at HH:MM in the local tz.
    # If the requested day is invalid for the month (e.g., 31 in February),
    # it clamps to the last day of the month.
    def self.next_monthly_local_time(tz, hhmm, day_of_month, from: nil)
      zone_name = Scheduling::TimeZoneResolver.zone_name(tz)
      hour, min = hhmm.split(":").map(&:to_i)

      Time.use_zone(zone_name) do
        now = from ? from.in_time_zone(zone_name) : Time.zone.now
        y, m = now.year, now.month

        # Clamp invalid days to end-of-month
        end_of_month_day = Date.civil(y, m, -1).day
        dom = [day_of_month.to_i, end_of_month_day].min

        candidate = Time.zone.local(y, m, dom, hour, min, 0)
        candidate += 1.month if candidate <= now
        candidate.utc
      end
    end
  end
end
