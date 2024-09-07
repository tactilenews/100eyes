# frozen_string_literal: true

module Organizations
  class ChartsController < ApplicationController
    def day_and_time_replies
      series = weekdays_starting_monday.map do |day|
        { name: day, data: day_and_time_data(joined_inbound(%i[day_of_week hour_of_day]), day) }
      end
      render json: series
    end

    def day_and_time_requests
      series = weekdays_starting_monday.map do |day|
        { name: day, data: day_and_time_data(joined_outbound(%i[day_of_week hour_of_day]), day) }
      end
      render json: series
    end

    def day_requests_replies
      render json: [{
        name: t('shared.community'), data: joined_inbound([:day_of_week]).map do |key, value|
                                            { x: key, y: value }
                                          end
      },
                    { name: t('shared.editorial'), data: joined_outbound([:day_of_week]).map { |key, value| { x: key, y: value } } }]
    end

    private

    def joined_inbound(group_keys)
      group_messages(@organization.messages.unscoped.replies, group_keys).count
    end

    def joined_outbound(group_keys)
      grouped_requests = group_messages(@organization.requests.unscoped, group_keys).count
      grouped_messages = group_messages(@organization.messages.unscoped.where(sender_type: [User.name, nil], broadcasted: false),
                                        group_keys).count
      grouped_requests.merge(grouped_messages) { |_key, oldval, newval| oldval + newval }
    end

    def group_messages(messages, group_keys)
      column = messages.any? && messages.all? { |message| message.is_a? Request } ? :broadcasted_at : :created_at
      messages = messages.group_by_day_of_week(column, format: '%A', week_start: :monday) if group_keys.include?(:day_of_week)
      return messages unless group_keys.include?(:hour_of_day)

      messages.group_by_hour_of_day(column, format: '%H:%M')
    end

    def day_and_time_data(messages, day)
      messages.map do |key, value|
        { x: key.last, y: value } if day == key.first
      end.compact
    end

    def weekdays_starting_monday
      t('date.day_names').reverse.rotate(-1)
    end
  end
end
