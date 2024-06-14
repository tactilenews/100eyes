# frozen_string_literal: true

class ResubscribeContributorJob < ApplicationJob
  queue_as :resubscribe_contributor

  class ResubscribeError < StandardError; end

  def perform(contributor_id, adapter)
    contributor = Contributor.find_by(id: contributor_id)
    return unless contributor

    if contributor.deactivated_by_user.present? || contributor.deactivated_by_admin?
      deactivated_by = (contributor.deactivated_by_user&.name || 'an admin')
      exception = ResubscribeContributorJob::ResubscribeError.new(
        "Contributor #{contributor.name} has been deactivated by #{deactivated_by} and has tried to re-subscribe"
      )
      ErrorNotifier.report(exception)
      adapter.send_resubscribe_error_message!(contributor)
      return
    end

    contributor.update!(unsubscribed_at: nil)
    # TODO: Refactor to pass organization into job
    organization = contributor.organization
    adapter.send_welcome_message!(contributor, organization)
    ContributorSubscribed.with(
      contributor_id: contributor.id,
      organization_id: organization.id
    ).deliver_later(organization.users + User.admin.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_resubscribed!(admin, contributor)
    end
  end
end
