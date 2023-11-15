# frozen_string_literal: true

class ResubscribeContributorJob < ApplicationJob
  queue_as :resubscribe_contributor

  def perform(contributor_id, adapter)
    contributor = Contributor.find(contributor_id)
    return unless contributor

    if contributor.deactivated_by_user.present? || contributor.deactivated_by_admin?
      exception = StandardError.new(
        "Contributor #{contributor.name} has been deactivated by #{contributor.deactivated_by_user&.name || 'an admin'} and has tried to re-subscribe"
      )
      ErrorNotifier.report(exception)
      adapter.send_resubscribe_error_message!(contributor, I18n.t('jobs.resubscribed_contributor_job.resubscribed_error'))
      return
    end

    contributor.update!(unsubscribed_at: nil)
    adapter.send_welcome_message!(contributor)
    ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
    end
  end
end
