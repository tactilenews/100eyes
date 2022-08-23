# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :set_current_user, only: :index

  def index
    @activity_notifications =
      if message_received.any?
        grouped_by_request = message_received.group_by(&:request)
        latest_message_received_per_request = grouped_by_request.map { |_key, value| value.first }
        (onboarding_completed + latest_message_received_per_request).sort_by(&:created_at).reverse!
      else
        onboarding_completed
      end
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def onboarding_completed
    current_user
      .notifications
      .includes(:contributor)
      .onboarding_completed
      .newest_first
      .limit(20)
  end

  def message_received
    current_user
      .notifications
      .includes(:contributor, :request)
      .message_received
      .newest_first
  end
end
