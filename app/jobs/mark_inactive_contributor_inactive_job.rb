# frozen_string_literal: true

class MarkInactiveContributorInactiveJob < ApplicationJob
  queue_as :mark_inactive_contributor_inactive

  def perform(contributor_id:)
    contributor = Contributor.find(contributor_id)
    organization = contributor.organization

    contributor.deactivated_at = Time.current
    contributor.save(validate: false)
    ContributorMarkedInactive.with(
      contributor_id: contributor.id,
      organization_id: organization.id
    ).deliver_later(organization.users + User.admin.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor, organization)
    end
  end
end
