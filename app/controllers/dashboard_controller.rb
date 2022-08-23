# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :set_current_user, only: :index

  def index
    @activity_notifications = activity_notifications
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def onboarding_completed
    current_user
      .notifications
      .onboarding_completed
      .newest_first
  end

  def message_received
    current_user
      .notifications
      .message_received
      .newest_first
  end

  def chat_message_sent
    current_user
      .notifications
      .chat_message_sent
      .newest_first
  end

  def activity_notifications
    grouped_by_request = message_received.group_by(&:request)
    latest_message_received_per_request = grouped_by_request.map { |_key, value| value.first }
    (onboarding_completed + latest_message_received_per_request + chat_message_sent).sort_by(&:created_at).reverse!
  end
end
