# frozen_string_literal: true

class MarkInactiveContributorInactiveJob < ApplicationJob
  queue_as :deactivate_contributor

  def perform(contributor_id:)
    contributor = Contributor.where(id: contributor_id).first
    return unless contributor

    contributor.deactivated_at = Time.current
    contributor.save(validate: false)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
    end
  end
end
