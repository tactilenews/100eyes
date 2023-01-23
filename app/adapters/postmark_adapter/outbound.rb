# frozen_string_literal: true

module PostmarkAdapter
  class Outbound < ApplicationMailer
    default template_name: :mailer
    default from: -> { default_from }

    rescue_from Postmark::InactiveRecipientError do |exception|
      ErrorNotifier.report(exception, context: { recipients: exception.recipients }, tags: { support: 'yes' })
      exception.recipients.each do |email_address|
        contributor = Contributor.find_by(email: email_address)
        next unless contributor

        contributor.update(deactivated_at: Time.current)
        ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
        User.admin.find_each do |admin|
          PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor, exception.message)
        end
      end
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

    def self.contributor_marked_as_inactive!(admin, contributor, text)
      return unless admin&.email && admin&.admin? && contributor&.id

      with(admin: admin, contributor: contributor, text: text).contributor_marked_as_inactive_email.deliver_later
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
      if @msg.broadcasted?
        broadcasted_message_email
      else
        reply_message_email
      end
    end

    def contributor_marked_as_inactive_email
      contributor = params[:contributor]
      admin = params[:admin]
      subject = I18n.t('adapter.shared.contributor_marked_as_inactive_email.subject', project_name: Setting.project_name,
                                                                                      contributor_name: contributor.name,
                                                                                      channel: contributor.channels.first.to_s.camelize)
      text = params[:text]
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    private

    def broadcasted_message_email
      headers({ 'message-id': "request/#{msg.request.id}@#{Setting.application_host}" })
      email_subject = I18n.t('adapter.postmark.new_message_email.subject')
      message_stream = Setting.postmark_broadcasts_stream
      attach_files if msg.files.present?
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

    def attach_files
      msg.files.each do |file|
        attachments.inline[file.attachment.filename.to_s] =
          File.read(ActiveStorage::Blob.service.path_for(file.attachment.blob.key))
      end
    end
  end
end
