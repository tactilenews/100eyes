# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    def self.send!(message)
      recipient = message.recipient
      return unless message.recipient&.threema_id

      files = message.files

      if files.present?
        files.each_with_index do |file, index|
          conditionally_schedule(ThreemaAdapter::Outbound::File, message).perform_later(
            recipient: recipient,
            file_path: ActiveStorage::Blob.service.path_for(file.attachment.blob.key),
            file_name: file.attachment.blob.filename.to_s,
            caption: index.zero? ? message.text : nil,
            render_type: :media
          )
        end
      else
        conditionally_schedule(ThreemaAdapter::Outbound::Text, message).perform_later(recipient: recipient, text: message.text)
      end
    end

    def self.welcome_message
      ["*#{Setting.onboarding_success_heading.strip}*", Setting.onboarding_success_text].join("\n")
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.threema_id

      ThreemaAdapter::Outbound::Text.perform_later(text: welcome_message, recipient: contributor)
    end

    def self.conditionally_schedule(message_type, message)
      message_type.try do |klass|
        message.request.schedule_send_for.present? ? klass.set(wait_until: message.request.schedule_send_for) : klass
      end
    end
  end
end
