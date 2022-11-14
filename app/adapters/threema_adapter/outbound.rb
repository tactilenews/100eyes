# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    queue_as :default

    rescue_from RuntimeError do |exception|
      tags = exception.message.match?(/Can't find public key for Threema ID/) ? { support: 'yes' } : {}
      ErrorNotifier.report(exception, tags: tags)
    end

    def self.send!(message)
      recipient = message.recipient
      return unless message.recipient&.threema_id

      image = message.request.image

      if image.attached?
        params = {
          recipient: recipient,
          file_path: ActiveStorage::Blob.service.path_for(image.blob.key),
          file_name: image.blob.filename.to_s,
          caption: message.text
        }
        params.merge!(thumbnail: ActiveStorage::Blob.service.path_for(image.blob.key)) if image.blob.variable?
        ThreemaAdapter::Outbound::File.perform_later(params)
      else
        perform_later(recipient: recipient, text: message.text)
      end
    end

    def self.welcome_message
      ["*#{Setting.onboarding_success_heading.strip}*", Setting.onboarding_success_text].join("\n")
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.threema_id

      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(recipient:, text: nil)
      self.class.threema_instance.send(type: :text, threema_id: recipient.threema_id.upcase, text: text)
    end
  end
end
