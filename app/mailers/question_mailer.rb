# frozen_string_literal: true

class QuestionMailer < ApplicationMailer
  def new_question_email
    mail(
      to: params[:to],
      subject: default_i18n_subject,
      body: params[:question]
    )
  end

  def new_message_email
    mail(
      to: params[:to],
      subject: default_i18n_subject,
      body: params[:message]
    )
  end
end
