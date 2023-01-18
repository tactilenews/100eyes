# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      latest_message_received_at = recipient.latest_message_received_at
      text = if latest_message_received_at.blank? || latest_message_received_at < 24.hours.ago
               recipient.update(whats_app_template_message_sent_at: Time.current)
               I18n.t("adapter.whats_app.request_template.new_request_#{time_of_day}_#{rand(1..3)}", first_name: recipient.first_name,
                                                                                                     request_title: message.request.title)
             else
               message.text
             end
      files = message.files

      if files.present?
        send_files(files, recipient, text)
      else
        send_text(recipient, text)
      end
    end

    def self.send_welcome_message!(contributor)
      return unless contributor_can_receive_messages?(contributor)

      welcome_message = I18n.t('adapter.whats_app.welcome_message', project_name: Setting.project_name)
      WhatsAppAdapter::Outbound::Text.perform_later(recipient: contributor, text: welcome_message)
    end

    def self.contributor_can_receive_messages?(recipient)
      recipient&.whats_app_phone_number.present?
    end

    def self.send_files(files, recipient, text)
      files.each_with_index do |file, index|
        WhatsAppAdapter::Outbound::File.perform_later(recipient: recipient, text: index.zero? ? text : '', file: file)
      end
    end

    def self.send_text(recipient, text)
      WhatsAppAdapter::Outbound::Text.perform_later(recipient: recipient, text: text)
    end

    def self.time_of_day
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
  end
end
