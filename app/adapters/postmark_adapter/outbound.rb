# frozen_string_literal: true

module PostmarkAdapter
  class Outbound < ApplicationMailer
    default template_name: :mailer
    default from: -> { default_from }

    rescue_from Postmark::InactiveRecipientError do |exception|
      ErrorNotifier.report(exception, context: { recipients: exception.recipients }, tags: { support: 'yes' })
    end

    attr_reader :msg

    def self.send!(message)
      return unless message.recipient&.email

      with(message: message).message_email.deliver_later
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.email

      with(contributor: contributor).welcome_email.deliver_later
    end

    def bounce_email
      @text = params[:text]
      mail(params[:mail])
    end

    def welcome_email
      contributor = params[:contributor]
      subject = Setting.onboarding_success_heading
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, Setting.onboarding_success_text].join("\n")
      mail(to: contributor.email, subject: subject, message_stream: message_stream)
    end

    def message_email
      @msg = params[:message]
      @text = msg.text
      if @msg.request.image
        attachments.inline[@msg.request.image.metadata['filename']] =
          File.read("public/#{@msg.request.image_url}")
      end
      if @msg.broadcasted?
        broadcasted_message_email
      else
        reply_message_email
      end
    end

    private

    def broadcasted_message_email
      headers({ 'message-id': "request/#{msg.request.id}@#{Setting.application_host}" })
      email_subject = I18n.t('adapter.postmark.new_message_email.subject')
      message_stream = Setting.postmark_broadcasts_stream
      mail(to: msg.recipient.email, subject: email_subject, message_stream: message_stream)
    end

    def reply_message_email
      headers({
                'message-id': "request/#{msg.request.id}/message/#{msg.id}@#{Setting.application_host}",
                references: "request/#{msg.request.id}@#{Setting.application_host}"
              })
      email_subject = "Re: #{I18n.t('adapter.postmark.new_message_email.subject')}"
      message_stream = Setting.postmark_transactional_stream
      mail(to: msg.recipient.email, subject: email_subject, message_stream: message_stream)
    end

    def default_from
      "\"#{Setting.project_name}\" <#{Setting.email_from_address}>"
    end
  end
end
