class ChartsController < ApplicationController
  def time_based_activity
    render json: Message.where.not(sender_id: nil).unscoped.group_by_hour_of_day(:created_at).count
  end
end
