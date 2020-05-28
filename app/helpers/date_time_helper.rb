# frozen_string_literal: true

module DateTimeHelper
  def date_time(date)
    return I18n.l date, format: :time_only if (Time.zone.now - 1.day) < date

    I18n.l date, format: :default
  end
end
