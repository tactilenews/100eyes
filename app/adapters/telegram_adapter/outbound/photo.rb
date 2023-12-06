# frozen_string_literal: true

module TelegramAdapter
  class Outbound
    class Photo < ApplicationJob
      queue_as :default
      discard_on Telegram::Bot::Forbidden do |job|
        message = job.arguments.first[:message]
        message&.update(blocked: true)
        contributor = message&.recipient
        return unless contributor

        MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id)
      end

      attr_reader :telegram_id, :message

      def perform(contributor_id:, media:, message: nil)
        contributor = Contributor.find(contributor_id)
        return unless contributor

        @telegram_id = contributor.telegram_id
        @message = message
        media_array = media.map.with_index do |photo, index|
          {
            type: 'photo',
            media: File.open(photo),
            caption: optional_caption(index)
          }
        end
        telegram_message = Telegram.bot.send_media_group(
          chat_id: telegram_id,
          media: media_array,
          parse_mode: :HTML
        )
        telegram_message = telegram_message.with_indifferent_access
        mark_message_as_received(telegram_message) if telegram_message[:ok]
      end

      private

      def optional_caption(index)
        if message.text.length >= 1024
          TelegramAdapter::Outbound::Text.perform_later(text: message.text, telegram_id: telegram_id, message: message)
          ''
        else
          index.zero? ? message.text : ''
        end
      end

      def mark_message_as_received(telegram_message)
        timestamp = telegram_message[:result].first[:date]
        external_id = telegram_message[:result].first[:message_id].to_s
        message.update!(received_at: Time.zone.at(timestamp).to_datetime, external_id: external_id)
      end
    end
  end
end
