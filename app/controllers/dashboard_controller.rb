# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    onboarding_completed = current_user.notifications.onboarding_completed.newest_first.limit(20)
    message_received = current_user.notifications.message_received.newest_first
    @count_per_request = []
    @activity_notifications =
      if message_received.any?
        grouped_by_request = message_received.group_by(&:request)
        latest_message_received_per_request = grouped_by_request.map { |_key, value| value.first }
        @count_per_request = grouped_by_request.map { |key, value| { key => value.count } }
        (onboarding_completed + latest_message_received_per_request).sort_by(&:created_at).reverse!
      else
        onboarding_completed
      end
  end
end
