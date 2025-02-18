# frozen_string_literal: true

class UnsubscribeContributorJob < ApplicationJob
  queue_as :unsubscribe_contributor

  def perform(contributor_id, adapter)
    contributor = Contributor.find(contributor_id)
    organization = contributor.organization
    return if contributor.unsubscribed_at.present?

    contributor.update!(unsubscribed_at: Time.current)
    adapter.send_unsubscribed_successfully_message!(contributor)
    ContributorMarkedInactive.with(
      contributor_id: contributor.id,
      organization_id: organization.id
    ).deliver_later(organization.users + User.admin.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_unsubscribed!(admin, contributor, organization)
    end
  end
end
