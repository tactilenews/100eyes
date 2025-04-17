# frozen_string_literal: true

module TelegramAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default
      discard_on Telegram::Bot::Forbidden do |job|
        message = job.arguments.first[:message]
        message&.update(blocked: true)
        contributor = message&.recipient
        return unless contributor

        MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id)
      end

      def perform(contributor_id:, text:, message: nil)
        contributor = Contributor.find(contributor_id)
        organization = contributor.organization

        @message = message

        response = organization.telegram_bot.send_message(
          chat_id: contributor.telegram_id,
          text: text,
          parse_mode: :HTML
        )
        response = response.with_indifferent_access
        mark_message_as_sent(response) if response[:ok] && message
      end

      attr_reader :message

      private

      def mark_message_as_sent(response)
        timestamp = response[:result][:date]
        external_id = response[:result][:message_id].to_s
        message.update!(sent_at: Time.zone.at(timestamp).to_datetime, external_id: external_id)
      end
    end
  end
end
