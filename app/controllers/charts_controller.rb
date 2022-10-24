# frozen_string_literal: true

class ChartsController < ApplicationController
  def time_based_replies
    render json: group_messages(Message.unscoped.replies).count
  end

  def time_based_requests
    grouped_requests = group_messages(Request.unscoped).count
    grouped_messages = group_messages(Message.unscoped.where(sender_type: [User.name, nil], broadcasted: false)).count
    joined_groups = grouped_requests.merge(grouped_messages) { |_key, oldval, newval| oldval + newval }
    render json: joined_groups
  end

  def day_requests_replies
    grouped_requests = Request.unscoped
                              .group_by_day_of_week(:created_at, format: '%A')
                              .count
    grouped_outbound_messages = Message.unscoped
                                       .where(sender_type: [User.name, nil], broadcasted: false)
                                       .group_by_day_of_week(:created_at, format: '%A')
                                       .count
    joined_outbound = grouped_requests.merge(grouped_outbound_messages) { |_key, oldval, newval| oldval + newval }
    render json: [{
      name: 'Eingegangene', data: Message.unscoped
                                         .replies
                                         .group_by_day_of_week(:created_at, format: '%A')
                                         .count
    },
                  { name: 'Fragen', data: joined_outbound }]
  end

  private

  def group_messages(messages)
    messages.group_by_day_of_week(:created_at, format: '%A')
            .group_by_hour_of_day(
              :created_at, format: '%H:%M'
            )
  end
end
