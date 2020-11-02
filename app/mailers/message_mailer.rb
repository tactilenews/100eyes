# frozen_string_literal: true

class MessageMailer < ApplicationMailer
  def new_message_email
    mail(
      to: params[:to],
      subject: default_i18n_subject,
      body: params[:text],
      message_stream: message_stream
    )
  end

  private

  def message_stream
    if params[:broadcasted]
      Setting.postmark_broadcasts_stream
    else
      Setting.postmark_transactional_stream
    end
  end
end
