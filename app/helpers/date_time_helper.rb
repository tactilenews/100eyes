# frozen_string_literal: true

module DateTimeHelper
  def date_time(date, format: nil)
    return I18n.l(date, format: format) if date.present?

    return I18n.l(date, format: :today) if date.today?

    I18n.l(date, format: :short)
  end
end
