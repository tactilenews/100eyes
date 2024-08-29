# frozen_string_literal: true

module Organizations
  class DashboardController < ApplicationController
    def index
      @activity_notifications = activity_notifications
      @active_contributors_count = @organization.contributors.active.count
      @requests_count = @organization.requests.count
      @replies_count = @organization.messages.replies.count
      @engagement_metric = engagement_metric
    end

    private

    def activity_notifications
      grouped = current_user.notifications_as_recipient
                            .where(organization_id: @organization.id)
                            .newest_first
                            .includes({ contributor: { avatar_attachment: :blob } }, :request, :message, :user)
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

    def engagement_metric
      current_weeks_activity = @organization.messages.replies.where('messages.created_at >= ?', 7.days.ago).count
      active_contributors_count = @organization.contributors.active.count
      return 0 unless active_contributors_count.positive?

      activity = (current_weeks_activity / active_contributors_count.to_f * 100)

      return 100 if activity > 100

      activity
    end
  end
end
