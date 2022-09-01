# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @activity_notifications = activity_notifications
  end

  private

  def activity_notifications
    grouped = current_user.activity_notifications
                          .newest_first
                          .includes(:contributor, :request, :message, :user)
                          .limit(100)
                          .group_by { |notification| notification.to_notification.group_key }
    grouped.map do |_key, notifications|
      {
        record: notifications.first.to_notification.record_for_avatar,
        group_message: notifications.first.to_notification.group_message(notifications: notifications),
        created_at: notifications.first.created_at,
        url: notifications.first.to_notification.url,
        link_text: notifications.first.to_notification.link_text
      }
    end
  end
end
