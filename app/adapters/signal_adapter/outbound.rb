# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class << self
      def send!(message)
        recipient = message&.recipient
        return unless contributor_can_receive_messages?(recipient)

        if message.files.present?
          SignalAdapter::Outbound::File.perform_later(message: message)
        else
          SignalAdapter::Outbound::Text.perform_later(contributor_id: recipient.id, text: message.text)
        end
      end

      def send_unknown_content_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor, text: Setting.signal_unknown_content_message)
      end

      def send_welcome_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        welcome_message = [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n")
        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id, text: welcome_message)
      end

      def send_unsubsribed_successfully_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = [I18n.t('adapter.shared.unsubscribe.successful'), I18n.t('adapter.shared.subscribe.instructions')].join("\n\n")
        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id, text: text)
      end

      def send_resubscribe_error_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id,
                                                    text: I18n.t('adapter.shared.subscribe.resubscribe_failure'))
      end

      def contributor_can_receive_messages?(recipient)
        recipient&.signal_phone_number.present? && recipient.signal_onboarding_completed_at.present?
      end
    end
  end
end
