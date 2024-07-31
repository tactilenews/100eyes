# frozen_string_literal: true

class UnsubscribeContributorJob < ApplicationJob
  queue_as :unsubscribe_contributor

  def perform(organization_id, contributor_id, adapter)
    organization = Organization.find_by(id: organization_id)
    return unless organization

    contributor = organization.contributors.find_by(id: contributor_id)
    return unless contributor
    return if contributor.unsubscribed_at.present?

    contributor.update!(unsubscribed_at: Time.current)
    adapter.send_unsubsribed_successfully_message!(contributor, organization)
    ContributorMarkedInactive.with(
      contributor_id: contributor.id,
      organization_id: organization.id
    ).deliver_later(organization.users + User.admin.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_unsubscribed!(admin, contributor, organization)
    end
  end
end
