# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module PostmarkAdapter
  class Outbound < ApplicationMailer
    default template_name: :mailer
    default from: -> { default_from }

    rescue_from Postmark::InactiveRecipientError do |exception|
      ErrorNotifier.report(exception, context: { recipients: exception.recipients }, tags: { support: 'yes' })

      exception.recipients.each do |email_address|
        contributor = organization.contributors.find_by(email: email_address)
        next unless contributor

        MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id)
      end
    end

    before_action do
      @organization = params[:organization]
    end

    attr_reader :msg, :organization

    class << self
      def send!(message)
        return unless message.recipient&.email

        with(message: message, organization: message.organization).message_email.deliver_later
      end

      def send_welcome_message!(contributor)
        return unless contributor&.email

        organization = contributor.organization
        with(contributor: contributor, organization: organization).welcome_email.deliver_later
      end

      def send_business_plan_upgraded_message!(admin, organization)
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

      def send_user_count_exceeds_plan_limit_message!(admin, organization)
        return unless admin&.email && admin&.admin? && organization&.id

        with(admin: admin, organization: organization).user_count_exceeds_plan_limit_email.deliver_later
      end

      def contributor_marked_as_inactive!(admin, contributor, organization)
        return unless admin&.email && admin&.admin? && contributor&.id && organization&.id && admin.email != contributor.email

        with(admin: admin, contributor: contributor, organization: organization).contributor_marked_as_inactive_email.deliver_later
      end

      def contributor_unsubscribed!(admin, contributor, organization)
        return unless admin&.email && admin&.admin? && contributor&.id && organization&.id

        with(admin: admin, contributor: contributor, organization: organization).contributor_unsubscribed_email.deliver_later
      end

      def contributor_resubscribed!(admin, contributor, organization)
        return unless admin&.email && admin&.admin? && contributor&.id && organization&.id

        with(admin: admin, contributor: contributor, organization: organization).contributor_resubscribed_email.deliver_later
      end

      def welcome_message_updated!(admin, organization)
        return unless admin&.email && admin&.admin? && organization.id

        with(admin: admin, organization: organization).welcome_message_updated_email.deliver_later
      end

      def send_request_csv_to_user!(user_id:, request_id:)
        user = User.find(user_id)
        request = Request.find(request_id)

        with(user: user, request_id: request_id, organization: request.organization).request_csv_email.deliver_later
      end
    end

    def bounce_email
      @text = params[:text]
      mail(params[:mail])
    end

    def welcome_email
      contributor = params[:contributor]
      subject = organization.onboarding_success_heading
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, organization.onboarding_success_text].join("\n")
      mail(to: contributor.email, subject: subject, message_stream: message_stream)
    end

    def business_plan_upgraded_email
      admin = params[:admin]
      price_per_month_with_discount = params[:price_per_month_with_discount]
      subject = I18n.t('adapter.postmark.business_plan_upgraded.subject',
                       organization_name: organization.name,
                       business_plan_name: organization.business_plan.name,
                       discount: organization.upgrade_discount)
      text = I18n.t('adapter.postmark.business_plan_upgraded.text',
                    organization_name: organization.name,
                    price_per_month_with_discount: price_per_month_with_discount,
                    valid_through: I18n.l(organization.upgraded_business_plan_at + 6.months, format: '%m/%Y'))
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def user_count_exceeds_plan_limit_email
      admin = params[:admin]
      subject = I18n.t('adapter.postmark.user_count_exceeds_plan_limit.subject',
                       organization_name: organization.name,
                       business_plan_name: organization.business_plan.name,
                       users_limit: organization.business_plan.number_of_users)
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, I18n.t('adapter.postmark.user_count_exceeds_plan_limit.text', organization_name: organization.name)].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def contributor_marked_as_inactive_email
      contributor = params[:contributor]
      admin = params[:admin]
      subject = I18n.t('adapter.postmark.contributor_marked_as_inactive_email.subject', project_name: organization.project_name,
                                                                                        contributor_name: contributor.name,
                                                                                        channel: contributor.channels.first.to_s.camelize)
      text = I18n.t('adapter.postmark.contributor_marked_as_inactive_email.text', contributor_name: contributor.name)
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def contributor_unsubscribed_email
      contributor = params[:contributor]
      admin = params[:admin]
      channel = contributor.channels.first.to_s.camelize
      subject = I18n.t('adapter.postmark.contributor_unsubscribed_email.subject', project_name: organization.project_name,
                                                                                  contributor_name: contributor.name,
                                                                                  channel: channel)
      text = I18n.t('adapter.postmark.contributor_marked_as_inactive_email.text', contributor_name: contributor.name, channel: channel)
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def contributor_resubscribed_email
      contributor = params[:contributor]
      admin = params[:admin]
      subject = I18n.t('adapter.postmark.contributor_resubscribed_email.subject', project_name: organization.project_name,
                                                                                  contributor_name: contributor.name,
                                                                                  channel: contributor.channels.first.to_s.camelize)
      text = I18n.t(
        'adapter.shared.resubscribe.by_request_of_contributor', contributor_name: contributor.name
      )
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def welcome_message_updated_email
      admin = params[:admin]

      subject = I18n.t('adapter.postmark.welcome_message_updated.subject', project_name: organization.project_name)
      text = I18n.t('adapter.postmark.welcome_message_updated.text')
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      @text = [subject, text].join("\n")
      mail(to: admin.email, subject: subject, message_stream: message_stream)
    end

    def request_csv_email
      user = params[:user]
      request_id = params[:request_id]

      file = Requests::GenerateCsvService.call(request_id: request_id)
      request = Request.find(request_id)
      subject = I18n.t('adapter.postmark.request_csv_email.subject', request_title: request.title)
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      file_name = "#{Time.zone.now.strftime('%Y_%m_%d')}_#{request.title.parameterize.underscore}.csv"
      attachments.inline[file_name] = file.read
      file.close!
      mail(to: user.email, subject: subject, message_stream: message_stream)
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
      headers({ 'message-id': "request/#{msg.request.id}@#{ENV.fetch('APPLICATION_HOSTNAME', 'localhost:3000')}" })
      email_subject = I18n.t('adapter.postmark.new_message_email.subject')
      message_stream = ENV.fetch('POSTMARK_BROADCASTS_STREAM', 'broadcasts')
      attach_files if msg.files.present?
      mail(to: msg.recipient.email, subject: email_subject,
           message_stream: message_stream)
    end

    def reply_message_email
      headers({
                'message-id': "request/#{msg.request.id}/message/#{msg.id}@#{ENV.fetch('APPLICATION_HOSTNAME', 'localhost:3000')}",
                references: "request/#{msg.request.id}@#{ENV.fetch('APPLICATION_HOSTNAME', 'localhost:3000')}"
              })
      email_subject = "Re: #{I18n.t('adapter.postmark.new_message_email.subject')}"
      message_stream = ENV.fetch('POSTMARK_TRANSACTIONAL_STREAM', 'outbound')
      mail(to: msg.recipient.email, subject: email_subject,
           message_stream: message_stream)
    end

    def default_from
      "\"#{organization.project_name}\" <#{organization.email_from_address}>"
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
