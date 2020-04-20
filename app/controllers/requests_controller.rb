# frozen_string_literal: true

class RequestsController < ApplicationController
  def new; end

  def create
    question = params[:question]
    QuestionMailer
      .with(question: question)
      .new_question_email
      .deliver_now
    User.where.not(telegram_chat_id: nil).find_each do |user|
      Telegram.bot.send_message(chat_id: user.telegram_chat_id, text: question)
    end
  end
end
