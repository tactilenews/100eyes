# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    def self.send!(message)
      recipient = message.recipient
      return unless recipient&.telegram_id

      files = message.files
      if files.present?
        media = files.map { |file| ActiveStorage::Blob.service.path_for(file.attachment.blob.key) }
        conditionally_schedule(TelegramAdapter::Outbound::Photo, message).perform_later(telegram_id: recipient.telegram_id,
                                                                                        media: media,
                                                                                        message: message)
      else
        conditionally_schedule(TelegramAdapter::Outbound::Text, message).perform_later(text: message.text, recipient: recipient,
                                                                                       message: message)
      end
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.telegram_id

      welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
      TelegramAdapter::Outbound::Text.perform_later(text: welcome_message, recipient: contributor)
    end

    def self.conditionally_schedule(message_type, message)
      message_type.try do |klass|
        message.request.schedule_send_for.present? ? klass.set(wait_until: message.request.schedule_send_for) : klass
      end
    end
  end
end
