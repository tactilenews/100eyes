# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    class << self
      def send!(message)
        return unless message.recipient&.threema_id

        files = message.files

        if files.present?
          send_files(files, message)
        else
          send_text(message)
        end
      end

      def welcome_message
        ["*#{Setting.onboarding_success_heading.strip}*", Setting.onboarding_success_text].join("\n")
      end

      def send_welcome_message!(contributor)
        return unless contributor&.threema_id

        ThreemaAdapter::Outbound::Text.perform_later(text: welcome_message, recipient: contributor)
      end

      def send_unsupported_content_message!(contributor)
        return unless contributor&.threema_id

        ThreemaAdapter::Outbound::Text.perform_later(text: Setting.threema_unknown_content_message, recipient: contributor)
      end

      def send_files(files, message)
        files.each_with_index do |file, index|
          ThreemaAdapter::Outbound::File.perform_later(
            recipient: message.recipient,
            file_path: ActiveStorage::Blob.service.path_for(file.attachment.blob.key),
            file_name: file.attachment.blob.filename.to_s,
            caption: index.zero? ? message.text : nil,
            render_type: :media
          )
        end
      end

      def send_text(message)
        ThreemaAdapter::Outbound::Text.perform_later(recipient: message.recipient, text: message.text)
      end
    end
  end
end
