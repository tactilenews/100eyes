# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    def self.send!(message)
      recipient = message.recipient
      return unless message.recipient&.threema_id

      image = message.request.image

      if image.attached?
        ThreemaAdapter::Outbound::File.perform_later(
          recipient: recipient,
          file_path: ActiveStorage::Blob.service.path_for(image.blob.key),
          file_name: image.blob.filename.to_s,
          caption: message.text,
          thumbnail: ActiveStorage::Blob.service.path_for(image.blob.key)
        )
      else
        ThreemaAdapter::Outbound::Text.perform_later(recipient: recipient, text: message.text)
      end
    end

    def self.welcome_message
      ["*#{Setting.onboarding_success_heading.strip}*", Setting.onboarding_success_text].join("\n")
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.threema_id

      ThreemaAdapter::Outbound::Text.perform_later(text: welcome_message, recipient: contributor)
    end
  end
end
