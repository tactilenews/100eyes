# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    queue_as :default

    rescue_from RuntimeError do |exception|
      tags = exception.message.match?(/Can't find public key for Threema ID/) ? { support: 'yes' } : {}
      ErrorNotifier.report(exception, tags: tags)
    end

    def self.threema_instance
      @threema_instance ||= Threema.new
    end

    def self.send!(message)
      recipient = message.recipient
      return unless message.recipient&.threema_id

      perform_later(recipient: recipient, text: message.text)
    end

    def self.welcome_message
      ["*#{Setting.onboarding_success_heading.strip}*", Setting.onboarding_success_text].join("\n")
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.threema_id

      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(recipient:, text:)
      self.class.threema_instance.send(type: :text, threema_id: recipient.threema_id.upcase, text: text)
    end
  end
end
