# frozen_string_literal: true

module TelegramAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default
      discard_on Telegram::Bot::Forbidden do |job|
        message = job.arguments.first[:message]
        message&.update(blocked: true)
        contributor = message.recipient
        return unless contributor

        contributor.update(deactivated_at: Time.current)
        ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
        User.admin.find_each do |admin|
          PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
        end
      end

      def perform(text:, telegram_id:, message: nil)  # rubocop:disable Lint/UnusedMethodArgument
        Telegram.bot.send_message(
          chat_id: telegram_id,
          text: text,
          parse_mode: :HTML
        )
      end
    end
  end
end
