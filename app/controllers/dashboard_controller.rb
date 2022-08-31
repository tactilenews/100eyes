# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @activity_notifications = activity_notifications
  end

  private

  def activity_notifications
    grouped = current_user.notifications
                          .newest_first.limit(100)
                          .group_by { |notification| notification.to_notification.group_key }
    grouped.map do |_key, notifications|
      {
        record: notifications.first.to_notification.record,
        group_message: notifications.first.to_notification.group_message(notifications: notifications),
        created_at: notifications.first.created_at,
        url: notifications.first.to_notification.url,
        link_text: notifications.first.to_notification.link_text
      }
    end
  end
end
