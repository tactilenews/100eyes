# frozen_string_literal: true

class QuestionMailer < ApplicationMailer
  def new_question_email
    mail(
      to: params[:to],
      subject: 'Die Redaktion hat eine neue Frage an Sie',
      body: params[:question]
    )
  end
end
