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

        MarkInactiveContributorInactiveJob.perform_later(organization_id: job.arguments.first[:organization_id],
                                                         contributor_id: contributor.id)
      end

      attr_reader :telegram_id, :message

      def perform(organization_id:, contributor_id:, media:, message:)
        organization = Organization.find(organization_id)
        contributor = organization.contributors.find(contributor_id)

        @telegram_id = contributor.telegram_id
        @message = message
        media_array = media.map.with_index do |photo, index|
          {
            type: 'photo',
            media: File.open(photo),
            caption: optional_caption(index)
          }
        end
        response = organization.telegram_bot.send_media_group(
          chat_id: telegram_id,
          media: media_array,
          parse_mode: :HTML
        )
        response = response.with_indifferent_access
        mark_message_as_sent(response) if response[:ok]
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end

      private

      def optional_caption(index)
        if message.text.length >= 1024
          TelegramAdapter::Outbound::Text.perform_later(text: message.text, contributor_id: message.recipient.id, message: message)
          ''
        else
          index.zero? ? message.text : ''
        end
      end

      def mark_message_as_sent(response)
        timestamp = response[:result].first[:date]
        external_id = response[:result].first[:message_id].to_s
        message.update!(sent_at: Time.zone.at(timestamp).to_datetime, external_id: external_id)
      end
    end
  end
end
