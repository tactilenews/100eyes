# frozen_string_literal: true

class UnsubscribeContributorJob < ApplicationJob
  queue_as :unsubscribe_contributor

  def perform(contributor_id, adapter)
    contributor = Contributor.find(contributor_id)
    return unless contributor

    contributor.update!(unsubscribed_at: Time.current)
    adapter.send_unsubsribed_successfully_message!(contributor)
    ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
    User.admin.find_each do |admin|
      PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
    end
  end
end
