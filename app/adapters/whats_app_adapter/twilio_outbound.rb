# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioOutbound
    class << self
      def send!(message)
        recipient = message&.recipient
        return unless contributor_can_receive_messages?(recipient)

        if freeform_message_permitted?(recipient)
          send_message(recipient, message)
        else
          send_message_template!(recipient, message)
        end
      end

      def send_welcome_message!(contributor, organization)
        return unless contributor_can_receive_messages?(contributor)

        welcome_message = ["*#{organization.onboarding_success_heading}*", organization.onboarding_success_text].join("\n\n")
        WhatsAppAdapter::TwilioOutbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id,
                                                            text: welcome_message)
      end

      def send_unsupported_content_message!(contributor, organization)
        return unless contributor_can_receive_messages?(contributor)

        text = I18n.t('adapter.whats_app.unsupported_content_template', first_name: contributor.first_name,
                                                                        contact_person: organization.contact_person.name)
        WhatsAppAdapter::TwilioOutbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id, text: text)
      end

      def send_more_info_message!(contributor, organization)
        return unless contributor_can_receive_messages?(contributor)

        text = [organization.whats_app_profile_about, "_#{I18n.t('adapter.shared.unsubscribe.instructions')}_"].join("\n\n")
        WhatsAppAdapter::TwilioOutbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id, text: text)
      end

      def send_unsubsribed_successfully_message!(contributor, organization)
        return unless contributor_can_receive_messages?(contributor)

        text = [I18n.t('adapter.shared.unsubscribe.successful'), "_#{I18n.t('adapter.shared.resubscribe.instructions')}_"].join("\n\n")
        WhatsAppAdapter::TwilioOutbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id, text: text)
      end

      def send_resubscribe_error_message!(contributor, organization)
        return unless contributor_can_receive_messages?(contributor)

        WhatsAppAdapter::TwilioOutbound::Text.perform_later(organization_id: organization.id,
                                                            contributor_id: contributor.id,
                                                            text: I18n.t('adapter.shared.resubscribe.failure'))
      end

      def send_message_template!(recipient, message)
        recipient.update(whats_app_message_template_sent_at: Time.current)
        content_sid = message.organization.twilio_content_sids["new_request_#{time_of_day}#{rand(1..3)}"]
        WhatsAppAdapter::TwilioOutbound::Template.perform_later(content_sid: content_sid, message_id: message.id)
      end

      private

      def contributor_can_receive_messages?(recipient)
        recipient&.whats_app_phone_number.present?
      end

      def time_of_day
        current_time = Time.current
        morning = current_time.change(hour: 6)
        day = current_time.change(hour: 11)
        evening = current_time.change(hour: 17)
        night = current_time.change(hour: 23)

        case current_time
        when morning..day
          'morning'
        when day..evening
          'day'
        when evening..night
          'evening'
        else
          'night'
        end
      end

      def freeform_message_permitted?(recipient)
        responding_to_template_message = recipient.whats_app_message_template_responded_at.present? &&
                                         recipient.whats_app_message_template_responded_at > 24.hours.ago
        latest_message_received_within_last_24_hours = recipient.replies.first&.created_at.present? &&
                                                       recipient.replies.first.created_at > 24.hours.ago
        responding_to_template_message || latest_message_received_within_last_24_hours
      end

      def send_message(recipient, message)
        files = message.files

        if files.blank?
          WhatsAppAdapter::TwilioOutbound::Text.perform_later(organization_id: message.organization.id, contributor_id: recipient.id,
                                                              text: message.text, message: message)
        else
          WhatsAppAdapter::TwilioOutbound::File.perform_later(organization_id: message.organization.id, contributor_id: recipient.id,
                                                              message: message)
        end
      end
    end
  end
end
