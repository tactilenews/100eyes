# frozen_string_literal: true

module DateTimeHelper
  def date_time(date)
    return I18n.l date, format: :today if date.today?

    I18n.l date, format: :short
  end
end
