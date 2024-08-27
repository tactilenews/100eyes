# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    user_permitted?(@organization)

    @activity_notifications = activity_notifications
    @active_contributors_count = Contributor.active.count
    @requests_count = Request.count
    @replies_count = Message.replies.count
    @engagment_metric = engagment_metric
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

  def engagment_metric
    current_weeks_activity = Message.replies.where('created_at >= ?', 7.days.ago).count
    active_contributors_count = Contributor.active.count
    return 0 unless active_contributors_count.positive?

    activity = (current_weeks_activity / active_contributors_count.to_f * 100)

    return 100 if activity > 100

    activity
  end

  # TODO: remove as in ApplicationController as of https://github.com/tactilenews/100eyes/pull/1971/files/8e2b1fb04fdbc0434e0ca866453f5a52533f8cb2
  def user_permitted?(organization)
    raise ActionController::RoutingError, 'Not Found' unless current_user.admin? || current_user.organization_id == organization.id
  end

end
