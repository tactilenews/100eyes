# frozen_string_literal: true

class ReplyMailer < ApplicationMailer
  def user_not_found_email
    mail(
      to: params[:email],
      subject: default_i18n_subject,
      body: I18n.t('reply_mailer.user_not_found_email.body', email: params[:email])
    )
  end
end
