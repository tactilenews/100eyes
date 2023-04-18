# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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
          contributor_marked_as_inactive!(admin, contributor)
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

    def self.send_business_plan_upgraded_message!(admin, organization)
      return unless admin&.email && admin&.admin? && organization&.id

      price_per_month_with_discount = ActionController::Base.helpers.number_to_currency(
        organization.business_plan.price_per_month - (
          organization.business_plan.price_per_month * organization.upgrade_discount / 100.to_f
        ),
        locale: :de
      )

      with(admin: admin, organization: organization,
           price_per_month_with_discount: price_per_month_with_discount).business_plan_upgraded_email.deliver_later
    end

    def self.send_user_count_exceeds_plan_limit_message!(admin, organization)
      return unless admin&.email && admin&.admin? && organization&.id

      with(admin: admin, organization: organization).user_count_exceeds_plan_limit_email.deliver_later
    end

    def self.contributor_marked_as_inactive!(admin, contributor)
      return unless admin&.email && admin&.admin? && contributor&.id

      with(admin: admin, contributor: contributor).contributor_marked_as_inactive_email.deliver_later
    end

    def self.contributor_subscribed!(admin, contributor)
      return unless admin&.email && admin&.admin? && contributor&.id

      with(admin: admin, contributor: contributor).contributor_subscribed_email.deliver_later
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
      price_per_month_with_discount = params[:price_per_month_with_discount]
      subject = I18n.t('adapter.postmark.business_plan_upgraded.subject',
                       organization_name: organization.name,
                       business_plan_name: organization.business_plan.name,
                       discount: organization.upgrade_discount)
      text = I18n.t('adapter.postmark.business_plan_upgraded.text',
                    organization_name: organization.name,
                    price_per_month_with_discount: price_per_month_with_discount,
                    valid_through: I18n.l(organization.upgraded_business_plan_at + 6.months, format: '%m/%Y'))
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, text].join("\n")
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

    def contributor_marked_as_inactive_email
      contributor = params[:contributor]
      admin = params[:admin]
      subject = I18n.t('adapter.postmark.contributor_marked_as_inactive_email.subject', project_name: Setting.project_name,
                                                                                        contributor_name: contributor.name,
                                                                                        channel: contributor.channels.first.to_s.camelize)
      text = I18n.t('adapter.postmark.contributor_marked_as_inactive_email.text')
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def contributor_subscribed_email
      contributor = params[:contributor]
      admin = params[:admin]
      subject = I18n.t('adapter.postmark.contributor_subscribed_email.subject', project_name: Setting.project_name,
                                                                                contributor_name: contributor.name,
                                                                                channel: contributor.channels.first.to_s.camelize)
      text = I18n.t(
        'adapter.whats_app.subscribe.by_request_of_contributor', contributor_name: contributor.name
      )
      message_stream = Setting.postmark_transactional_stream
      @text = [subject, text].join("\n")
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
# rubocop:enable Metrics/ClassLength
