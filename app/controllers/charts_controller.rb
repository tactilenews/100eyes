# frozen_string_literal: true

class ChartsController < ApplicationController
  def time_based_replies
    render json: group_messages(Message.unscoped.replies).count
  end

  def time_based_requests
    render json: group_messages(Message.unscoped.where(sender_type: [User.name, nil])).count
  end

  private

  def group_messages(messages)
    messages.group_by_day_of_week(:created_at, format: '%A')
            .group_by_hour_of_day(
              :created_at, format: '%H:%M'
            )
  end
end
