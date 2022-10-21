# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    @activity_notifications = activity_notifications
    @active_contributors_count = Contributor.active.count
    @requests_count = Request.count
    @replies_count = Message.replies.count
  end

  private

  def activity_notifications
    grouped = current_user.notifications_as_recipient
                          .newest_first
                          .includes(:contributor, :request, :message, :user)
                          .last_four_weeks
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
