# frozen_string_literal: true

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
        WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: welcome_message)
      end

      def send_unsupported_content_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor,
                                                      text: I18n.t('adapter.whats_app.unsupported_content_template',
                                                                   first_name: contributor.first_name,
                                                                   contact_person: User.last.name))
      end

      def send_more_info_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = [Setting.about, "_#{I18n.t('adapter.whats_app.unsubscribe.instructions')}_"].join("\n\n")
        WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: text)
      end

      def send_unsubsribed_successfully_message!(contributor)
        return unless contributor_can_receive_messages?(contributor)

        text = [I18n.t('adapter.whats_app.unsubscribe.successful'), "_#{I18n.t('adapter.whats_app.subscribe.instructions')}_"].join("\n\n")
        WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: text)
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
        when night..morning
          'night'
        end
      end

      def freeform_message_permitted?(recipient)
        responding_to_template_message = recipient.whats_app_message_template_responded_at.present? &&
                                         recipient.whats_app_message_template_responded_at > 24.hours.ago
        latest_message_received_within_24_hours_ago = recipient.replies.first&.created_at.present? &&
                                                      recipient.replies.first.created_at > 24.hours.ago
        responding_to_template_message || latest_message_received_within_24_hours_ago
      end

      def send_message_template(recipient, message)
        recipient.update(whats_app_template_message_sent_at: Time.current)

        text = I18n.t("adapter.whats_app.request_template.new_request_#{time_of_day}_#{rand(1..3)}", first_name: recipient.first_name,
                                                                                                     request_title: message.request.title)
        WhatsAppAdapter::Outbound::Text.perform_later(recipient: recipient, text: text)
      end

      def send_message(recipient, message)
        files = message.files

        if files.blank?
          WhatsAppAdapter::Outbound::Text.perform_later(recipient: recipient, text: message.text)
        else
          files.each_with_index do |file, index|
            WhatsAppAdapter::Outbound::File.perform_later(recipient: recipient, text: index.zero? ? message.text : '', file: file)
          end
        end
      end
    end
  end
end
