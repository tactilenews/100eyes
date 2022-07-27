# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @activity_notifications = current_user.notifications.newest_first.limit(20)
  end
end
