class QuestionMailer < ApplicationMailer
  def new_question_email
    mail(
      to: 'somebody@example.org',
      subject: 'Die Redaktion hat eine neue Frage an dich',
      body: params[:question]
    )
  end
end
