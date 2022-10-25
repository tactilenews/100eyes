# frozen_string_literal: true

class ChartsController < ApplicationController
  def day_and_time_replies
    series = t('date.day_names').reverse.map do |day|
      { name: day, data: day_and_time_data(joined_inbound(%i[day_of_week hour_of_day]), day) }
    end
    render json: series
  end

  def day_and_time_requests
    series = t('date.day_names').reverse.map do |day|
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
    group_messages(Message.unscoped.replies, group_keys).count
  end

  def joined_outbound(group_keys)
    grouped_requests = group_messages(Request.unscoped, group_keys).count
    grouped_messages = group_messages(Message.unscoped.where(sender_type: [User.name, nil], broadcasted: false),
                                      group_keys).count
    grouped_requests.merge(grouped_messages) { |_key, oldval, newval| oldval + newval }
  end

  def group_messages(messages, group_keys)
    messages = messages.group_by_day_of_week(:created_at, format: '%A') if group_keys.include?(:day_of_week)
    return messages unless group_keys.include?(:hour_of_day)

    messages.group_by_hour_of_day(:created_at, format: '%H:%M')
  end

  def day_and_time_data(messages, day)
    messages.map do |key, value|
      { x: key.last, y: value } if day == key.first
    end.compact
  end
end
