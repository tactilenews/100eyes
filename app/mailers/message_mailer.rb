# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  def new_message_email
    mail(
      to: params[:to],
      subject: default_i18n_subject,
      body: params[:message]
    )
  end
end
