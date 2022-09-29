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
      subject = Setting.find_by(var: :onboarding_success_heading)
                       .send("value_#{contributor.localization_tags.first}".to_sym)
      message_stream = Setting.postmark_transactional_stream
      @text = [subject,
               Setting.find_by(var: :onboarding_success_text)
                      .send("value_#{contributor.localization_tags.first}").to_sym].join("\n")
      @locale = contributor.localization_tags.first.to_sym
      mail(to: contributor.email, subject: subject, message_stream: message_stream)
    end

    def message_email
      @msg = params[:message]
      @text = msg.text
      @locale = @msg.request.localization_tags&.first&.to_sym
      if @msg.broadcasted?
        broadcasted_message_email
      else
        reply_message_email
      end
    end

    private

    def broadcasted_message_email
      headers({ 'message-id': "request/#{msg.request.id}@#{Setting.application_host}" })
      email_subject = localized_email_subject(msg.request.localization_tags&.first&.to_sym)
      message_stream = Setting.postmark_broadcasts_stream
      mail(to: msg.recipient.email, subject: email_subject, message_stream: message_stream)
    end

    def reply_message_email
      headers({
                'message-id': "request/#{msg.request.id}/message/#{msg.id}@#{Setting.application_host}",
                references: "request/#{msg.request.id}@#{Setting.application_host}"
              })
      email_subject = "Re: #{localized_email_subject(msg.request.localization_tags&.first&.to_sym)}"
      message_stream = Setting.postmark_transactional_stream
      mail(to: msg.recipient.email, subject: email_subject, message_stream: message_stream)
    end

    def default_from
      "\"#{Setting.project_name}\" <#{Setting.email_from_address}>"
    end

    def localized_email_subject(locale)
      I18n.with_locale(locale) do
        I18n.t('adapter.postmark.new_message_email.subject')
      end
    end
  end
end
