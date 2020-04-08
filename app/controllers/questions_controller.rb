class QuestionsController < ApplicationController
  def new
  end

  def create
    QuestionMailer
      .with(question: params[:question])
      .new_question_email
      .deliver_now
  end
end
