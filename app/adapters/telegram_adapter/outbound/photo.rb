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

        contributor.update(deactivated_at: Time.current)
        ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
        User.admin.find_each do |admin|
          PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
        end
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
        Telegram.bot.send_media_group(
          chat_id: telegram_id,
          media: media_array,
          parse_mode: :HTML
        )
      end

      def optional_caption(index)
        if message.text.length >= 1024
          TelegramAdapter::Outbound::Text.perform_later(text: message.text, telegram_id: telegram_id, message: message)
          ''
        else
          index.zero? ? message.text : ''
        end
      end
    end
  end
end
