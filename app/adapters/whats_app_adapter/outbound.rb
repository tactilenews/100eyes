# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module WhatsAppAdapter
  class Outbound
    class << self
      def send!(message)
        recipient = message&.recipient
        return unless contributor_can_receive_messages?(recipient)

        if freeform_message_permitted?(recipient)
          send_message(recipient, message)
        else
          send_message_template(recipient, message)
        end
      end

      def send_welcome_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        welcome_message = I18n.t('adapter.whats_app.welcome_message', project_name: Setting.project_name)
        if Setting.three_sixty_dialog_api_key.present?
          payload = if freeform_message_permitted?(contributor)
                      text_payload(contributor, welcome_message)
                    else
                      welcome_message_payload(contributor)
                    end
          WhatsAppAdapter::Outbound::ThreeSixtyDialogText.perform_later(payload: payload)
        else
          WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: welcome_message)
        end
      end

      def send_unsupported_content_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = I18n.t('adapter.whats_app.unsupported_content_template', first_name: contributor.first_name,
                                                                        contact_person: contributor.organization.contact_person.name)
        if Setting.three_sixty_dialog_api_key.present?
          WhatsAppAdapter::Outbound::ThreeSixtyDialogText.perform_later(payload: text_payload(contributor, text))
        else
          WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: text)
        end
      end

      def send_more_info_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = [Setting.about, "_#{I18n.t('adapter.whats_app.unsubscribe.instructions')}_"].join("\n\n")
        if Setting.three_sixty_dialog_api_key.present?
          WhatsAppAdapter::Outbound::ThreeSixtyDialogText.perform_later(payload: text_payload(contributor, text))
        else
          WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: text)
        end
      end

      def send_unsubsribed_successfully_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = [I18n.t('adapter.whats_app.unsubscribe.successful'), "_#{I18n.t('adapter.whats_app.subscribe.instructions')}_"].join("\n\n")
        if Setting.three_sixty_dialog_api_key.present?
          WhatsAppAdapter::Outbound::ThreeSixtyDialogText.perform_later(payload: text_payload(contributor, text))
        else
          WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: text)
        end
      end

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

      def send_message_template(recipient, message)
        recipient.update(whats_app_message_template_sent_at: Time.current)
        if Setting.three_sixty_dialog_api_key.present?
          WhatsAppAdapter::Outbound::ThreeSixtyDialogText.perform_later(payload: new_request_payload(recipient, message.request))
        else
          text = I18n.t("adapter.whats_app.request_template.new_request_#{time_of_day}_#{rand(1..3)}", first_name: recipient.first_name,
                                                                                                       request_title: message.request.title)
          WhatsAppAdapter::Outbound::Text.perform_later(recipient: recipient, text: text)
        end
      end

      def send_message(recipient, message)
        files = message.files

        if files.blank?
          if Setting.three_sixty_dialog_api_key.present?
            WhatsAppAdapter::Outbound::ThreeSixtyDialogText.perform_later(payload: text_payload(recipient, message.text))
          else
            WhatsAppAdapter::Outbound::Text.perform_later
          end
        elsif Setting.three_sixty_dialog_api_key.present?
          files.each do |_file|
            WhatsAppAdapter::UploadFile.perform_later(message_id: message.id)
          end
        else
          files.each_with_index do |file, index|
            WhatsAppAdapter::Outbound::File.perform_later(recipient: recipient, text: index.zero? ? message.text : '', file: file)
          end
        end
      end

      # rubocop:disable Metrics/MethodLength
      def new_request_payload(recipient, request)
        {
          recipient_type: 'individual',
          to: recipient.whats_app_phone_number.split('+').last,
          type: 'template',
          template: {
            namespace: Setting.three_sixty_dialog_whats_app_template_namespace,
            language: {
              policy: 'deterministic',
              code: 'de'
            },
            name: 'new_request_morning_1', # TODO: Use dynamic template name after WhatsAppAdapter::CreateTemplate works
            components: [
              {
                type: 'body',
                parameters: [
                  {
                    type: 'text',
                    text: recipient.first_name
                  },
                  {
                    type: 'text',
                    text: request.title
                  }
                ]
              }
            ]
          }
        }
      end
      # rubocop:enable Metrics/MethodLength

      def text_payload(recipient, text)
        {
          recipient_type: 'individual',
          to: recipient.whats_app_phone_number.split('+').last,
          type: 'text',
          text: {
            body: text
          }
        }
      end

      def welcome_message_payload(recipient)
        {
          recipient_type: 'individual',
          to: recipient.whats_app_phone_number.split('+').last,
          type: 'template',
          template: {
            namespace: template_namespace,
            language: {
              policy: 'deterministic',
              code: 'de'
            },
            name: 'welcome_message'
          }
        }
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
