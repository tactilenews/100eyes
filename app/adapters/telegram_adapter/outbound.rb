# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    queue_as :default
    discard_on Telegram::Bot::Forbidden do |job|
      message = job.arguments.first[:message]
      message&.update(blocked: true)
    end

    def self.send!(message)
      recipient = message.recipient
      return unless recipient&.telegram_id

      perform_later(text: message.text, recipient: recipient, message: message)
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.telegram_id

      welcome_message = ["<b>#{Setting.find_by(var: :onboarding_success_heading).send("value_#{I18n.locale}".to_sym)}</b>",
                         Setting.find_by(var: :onboarding_success_text).send("value_#{I18n.locale}".to_sym)].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(text:, recipient:, message: nil) # rubocop:disable Lint/UnusedMethodArgument
      Telegram.bot.send_message(
        chat_id: recipient.telegram_id,
        text: text,
        parse_mode: :HTML
      )
    end
  end
end
