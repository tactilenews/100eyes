# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogOutbound
    class << self
      def send!(message)
        contributor = message&.recipient
        return unless contributor_can_receive_messages?(contributor)

        if freeform_message_permitted?(contributor)
          send_message(message)
        else
          send_message_template(message)
        end
      end

      def send_welcome_message!(contributor, organization)
        return unless contributor_can_receive_messages?(contributor)

        if freeform_message_permitted?(contributor)
          welcome_message = ["*#{organization.onboarding_success_heading}*", organization.onboarding_success_text].join("\n\n")
          WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: contributor.id, type: :text,
                                                                        text: welcome_message)
        else
          WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: contributor.id, type: :welcome_message_template)
        end
      end

      def send_unsupported_content_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = I18n.t('adapter.whats_app.unsupported_content_template', first_name: contributor.first_name,
                                                                        contact_person: contributor.organization.contact_person.name)
        WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: contributor.id, type: :text, text: text)
      end

      def send_more_info_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: contributor.id, type: :text,
                                                                      text: contributor.organization.whats_app_more_info_message)
      end

      def send_unsubsribed_successfully_message!(contributor, _organization)
        return unless contributor_can_receive_messages?(contributor)

        text = [I18n.t('adapter.shared.unsubscribe.successful'),
                "_#{I18n.t('adapter.shared.resubscribe.instructions')}_"].join("\n\n")

        WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: contributor.id, type: :text, text: text)
      end

      def send_resubscribe_error_message!(contributor, _organization)
        return unless contributor_can_receive_messages?(contributor)

        text = I18n.t('adapter.shared.resubscribe.failure')
        WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: contributor.id, type: :text, text: text)
      end

      private

      def contributor_can_receive_messages?(contributor)
        contributor&.whats_app_phone_number.present?
      end

      def freeform_message_permitted?(contributor)
        responding_to_template_message = contributor.whats_app_message_template_responded_at.present? &&
                                         contributor.whats_app_message_template_responded_at > 24.hours.ago
        latest_message_received_within_last_24_hours = contributor.replies.first&.created_at.present? &&
                                                       contributor.replies.first.created_at > 24.hours.ago
        responding_to_template_message || latest_message_received_within_last_24_hours
      end

      def send_message_template(message)
        message.recipient.update(whats_app_message_template_sent_at: Time.current)
        WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: message.recipient.id,
                                                                      type: :request_template,
                                                                      message_id: message.id)
      end

      def send_message(message)
        if message.files.present?
          WhatsAppAdapter::ThreeSixtyDialogOutbound::File.perform_later(message_id: message.id)

        else

          WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(contributor_id: message.recipient.id,
                                                                        type: :text,
                                                                        message_id: message.id)
        end
      end
    end
  end
end
