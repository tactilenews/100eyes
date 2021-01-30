# frozen_string_literal: true

class Mailer < ApplicationMailer
  default template_name: :mailer
  default from: -> { default_from }

  def new_message_email
    stream = params[:broadcasted] ? broadcasts_stream : transactional_stream
    @text = params[:text]

    headers(params[:headers])
    mail(
      to: params[:to],
      subject: default_i18n_subject,
      message_stream: stream
    )
  end

  def contributor_not_found_email
    @text = I18n.t('mailer.contributor_not_found_email.text')
    mail(
      to: params[:email],
      subject: default_i18n_subject,
      message_stream: transactional_stream
    )
  end

  private

  def default_from
    "#{Setting.project_name} <#{Setting.email_from_address}>"
  end

  def broadcasts_stream
    Setting.postmark_broadcasts_stream
  end

  def transactional_stream
    Setting.postmark_transactional_stream
  end
end
