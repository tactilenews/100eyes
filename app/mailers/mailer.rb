# frozen_string_literal: true

class Mailer < ActionMailer::Base
  default template_name: :mailer

  def new_message_email
    stream = params[:broadcasted] ? broadcasts_stream : transactional_stream
    @text = params[:text]

    mail(
      to: params[:to],
      subject: default_i18n_subject,
      message_stream: stream
    )
  end

  def user_not_found_email
    @text = I18n.t('mailer.user_not_found_email.text')

    mail(
      to: params[:email],
      subject: default_i18n_subject,
      message_stream: transactional_stream
    )
  end

  private

  def broadcasts_stream
    Setting.postmark_broadcasts_stream
  end

  def transactional_stream
    Setting.postmark_transactional_stream
  end
end
