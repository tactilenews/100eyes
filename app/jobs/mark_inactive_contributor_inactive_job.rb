# frozen_string_literal: true

class MarkInactiveContributorInactiveJob < ApplicationJob
  queue_as :mark_inactive_contributor_inactive

  def perform(organization_id:, contributor_id:)
    organization = Organization.find_by(id: organization_id)
    return unless organization

    contributor = organization.contributors.where(id: contributor_id).first
    return unless contributor

    contributor.deactivated_at = Time.current
    contributor.save(validate: false)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor, organization)
    end
  end
end
