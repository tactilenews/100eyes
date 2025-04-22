# frozen_string_literal: true

module WhatsAppAdapter
  class HandleFailedMessageJob < ApplicationJob
    def perform(contributor_id:, external_message_id:)
      contributor = Contributor.find(contributor_id)
      message = Message.find_by(external_id: external_message_id) || Message::WhatsAppTemplate.find_by(external_id: external_message_id)
      return if message && message.delivered_at.present?

      contributor.whats_app_message_failed_count += 1
      contributor.save!
      MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id) if contributor.whats_app_message_failed_count >= 3
    end
  end
end
