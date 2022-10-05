# frozen_string_literal: true

class ChartsController < ApplicationController
  def time_based_activity
    render json: Message.where.not(sender_id: nil).unscoped.group_by_day_of_week(:created_at, format: '%A').group_by_hour_of_day(
      :created_at, format: '%H:%M'
    ).count
  end
end
