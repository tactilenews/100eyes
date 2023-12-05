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

      def perform(contributor_id:, message:)
        contributor = Contributor.find(contributor_id)
        return unless contributor

        @message = message

        telegram_message = Telegram.bot.send_message(
          chat_id: contributor.telegram_id,
          text: message.text,
          parse_mode: :HTML
        )
        telegram_message = telegram_message.with_indifferent_access
        mark_message_as_received(telegram_message) if telegram_message[:ok]
      end

      attr_reader :message

      private

      def mark_message_as_received(telegram_message)
        timestamp = telegram_message[:result][:date]
        message.update!(received_at: Time.zone.at(timestamp).to_datetime)
      end
    end
  end
end
