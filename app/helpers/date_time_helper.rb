# frozen_string_literal: true

module DateTimeHelper
  def date_time(date)
    return date.strftime('%H:%M') if (Time.zone.now - 1.day) < date

    date.strftime('%F %H:%M')
  end
end
