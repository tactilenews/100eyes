# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    class << self
      def send!(message)
        recipient = message.recipient
        return unless recipient&.telegram_id

        files = message.files
        if files.present?
          media = files.map { |file| ActiveStorage::Blob.service.path_for(file.attachment.blob.key) }
          TelegramAdapter::Outbound::Photo.perform_later(telegram_id: recipient.telegram_id,
                                                         media: media,
                                                         message: message)
        else
          TelegramAdapter::Outbound::Text.perform_later(text: message.text, telegram_id: recipient.telegram_id,
                                                        message: message)
        end
      end

      def send_welcome_message!(contributor)
        return unless contributor&.telegram_id

        welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
        TelegramAdapter::Outbound::Text.perform_later(text: welcome_message, telegram_id: contributor.telegram_id)
      end

      def send_unsubsribed_successfully_message!(contributor)
        return unless contributor&.telegram_id

        text = [I18n.t('adapter.shared.unsubscribe.successful'), "<em>#{I18n.t('adapter.shared.subscribe.instructions')}</em>"].join("\n\n")
        TelegramAdapter::Outbound::Text.perform_later(text: text, telegram_id: contributor.telegram_id)
      end
  end
  end
end
