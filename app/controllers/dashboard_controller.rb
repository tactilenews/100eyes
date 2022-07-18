# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @activity_notifications = current_user.notifications.limit(30)
  end
end
