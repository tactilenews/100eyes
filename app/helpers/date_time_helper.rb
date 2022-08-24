# frozen_string_literal: true

module DateTimeHelper
  def date_time(date, format: nil)
    return I18n.l(date, format: format) if date.present?

    return I18n.l(date, format: :today) if date.today?

    I18n.l(date, format: :short)
  end

  def time_based_heading
    current_time = Time.current
    midnight = current_time.beginning_of_day
    noon = current_time.noon
    evening = current_time.change(hour: 17)
    night = current_time.change(hour: 20)

    case current_time
    when midnight..noon
      '_morning'
    when noon..evening
      '_afternoon'
    when evening..night
      '_evening'
    else
      ''
    end
  end
end
