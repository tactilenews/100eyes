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
          SignalAdapter::Outbound::Text.perform_later(contributor_id: recipient.id,
                                                      text: message.text, message: message)
        end
      end

      def send_unsupported_content_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id,
                                                    text: contributor.organization.signal_unknown_content_message)
      end

      def send_welcome_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        organization = contributor.organization
        welcome_message = [organization.onboarding_success_heading, organization.onboarding_success_text].join("\n")
        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id, text: welcome_message)
      end

      def send_unsubscribed_successfully_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = [I18n.t('adapter.shared.unsubscribe.successful'), I18n.t('adapter.shared.resubscribe.instructions')].join("\n\n")
        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id, text: text)
      end

      def send_resubscribe_error_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        SignalAdapter::Outbound::Text.perform_later(contributor_id: contributor.id,
                                                    text: I18n.t('adapter.shared.resubscribe.failure'))
      end

      def contributor_can_receive_messages?(recipient)
        (recipient&.signal_phone_number.present? || recipient&.signal_uuid.present?) && recipient.signal_onboarding_completed_at.present?
      end
    end
  end
end
