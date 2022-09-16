# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @time_based_activity = Message.where.not(sender_id: nil).unscoped.group_by_day_of_week(:created_at, format: '%A').group_by_hour_of_day(:created_at).count
  end
end
