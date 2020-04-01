# frozen_string_literal: true

class QuestionsController < ApplicationController
  def new; end

  def create
    question = params[:question]
    QuestionMailer
      .with(question: question)
      .new_question_email
      .deliver_now
    User.where.not(chat_id: nil).find_each do |user|
      Telegram.bot.send_message(chat_id: user.chat_id, text: question)
    end
  end
end
