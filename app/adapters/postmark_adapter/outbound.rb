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

    def self.send_business_plan_upgraded_message!(admin, organization)
      return unless admin&.email && admin&.admin? && organization&.id

      with(admin: admin, organization: organization).business_plan_upgraded_email.deliver_later
    end

    def self.send_user_count_exceeds_plan_limit_message!(admin, organization)
      return unless admin&.email && admin&.admin? && organization&.id

      with(admin: admin, organization: organization).user_count_exceeds_plan_limit_email.deliver_later
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

    def business_plan_upgraded_email
      admin = params[:admin]
      organization = params[:organization]
      subject = I18n.t('adapter.postmark.business_plan_upgraded.subject',
                       organization_name: organization.name,
                       business_plan_name: organization.business_plan.name,
                       discount: organization.upgrade_discount)
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, I18n.t('adapter.postmark.business_plan_upgraded.text', organization_name: organization.name)].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def user_count_exceeds_plan_limit_email
      admin = params[:admin]
      organization = params[:organization]
      subject = I18n.t('adapter.postmark.user_count_exceeds_plan_limit.subject',
                       organization_name: organization.name,
                       business_plan_name: organization.business_plan.name,
                       users_limit: organization.business_plan.number_of_users)
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, I18n.t('adapter.postmark.user_count_exceeds_plan_limit.text', organization_name: organization.name)]
      mail(to: admin.email, subject: subject, message_stream: message_stream)
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
