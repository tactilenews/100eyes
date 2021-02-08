# frozen_string_literal: true

class EmailAdapter
  attr_reader :message

  delegate :request, to: :message
  delegate :recipient, to: :message
  delegate :broadcasted?, to: :message

  def initialize(message:)
    @message = message
  end

  def send!
    return unless recipient&.email

    Mailer
      .with(to: recipient.email, text: message.text, broadcasted: broadcasted?, headers: headers)
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
