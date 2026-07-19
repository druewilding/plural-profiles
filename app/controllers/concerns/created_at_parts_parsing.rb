module CreatedAtPartsParsing
  extend ActiveSupport::Concern

  private

  # Combines the month/day/year/hour/minute strings submitted by the
  # datetime-picker widget (see shared/_datetime_picker) into the
  # "YYYY-MM-DDTHH:MM" format the rest of the created_at handling expects.
  # Accepts the month as a name ("June") or a number. Returns nil for
  # blank, malformed, or out-of-range input.
  def parse_created_at_parts(parts)
    return nil if parts.blank?

    month = Date::MONTHNAMES.index { |name| name&.casecmp?(parts[:month].to_s.strip) }
    month ||= Integer(parts[:month], 10, exception: false)
    day = Integer(parts[:day], 10, exception: false)
    year = Integer(parts[:year], 10, exception: false)
    hour = Integer(parts[:hour], 10, exception: false)
    minute = Integer(parts[:minute], 10, exception: false)
    return nil if [ month, day, year, hour, minute ].any?(&:nil?)
    return nil unless Date.valid_date?(year, month, day) && (0..23).cover?(hour) && (0..59).cover?(minute)

    format("%04d-%02d-%02dT%02d:%02d", year, month, day, hour, minute)
  end
end
