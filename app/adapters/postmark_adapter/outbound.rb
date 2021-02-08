# frozen_string_literal: true

module PostmarkAdapter
  class Outbound
    attr_reader :message

    delegate :request, to: :message
    delegate :recipient, to: :message
    delegate :broadcasted?, to: :message

    def initialize(message:)
      @message = message
    end

    def subject
      subject = I18n.t('mailer.new_message_email.subject')
      subject = "Re: #{subject}" unless broadcasted?
      subject
    end

    def message_stream
      return Setting.postmark_broadcasts_stream if broadcasted?

      Setting.postmark_transactional_stream
    end

    def send!
      return unless recipient&.email

      Mailer
        .with(
          mail: { to: recipient.email, subject: subject, message_stream: message_stream },
          text: message.text,
          headers: headers
        )
        .new_message_email
        .deliver_later
    end

    def headers
      return { 'message-id': "request/#{request.id}@#{Setting.application_host}" } if broadcasted?

      {
        'message-id': "request/#{request.id}/message/#{message.id}@#{Setting.application_host}",
        references: "request/#{request.id}@#{Setting.application_host}"
      }
    end
  end
end
