# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_user, only: %i[show]
  before_action :set_request, only: %i[show]

  def new; end

  def create
    title = params[:title]
    text = params[:text]
    hints = params[:hints]

    request = Request.create!(
      title: title,
      text: text,
      hints: hints
    )

    User.where.not(email: nil).find_each do |user|
      QuestionMailer
        .with(question: request.plaintext, to: user.email)
        .new_question_email
        .deliver_later
    end

    User.where.not(telegram_chat_id: nil).find_each do |user|
      Telegram.bots[Rails.configuration.bot_id].send_message(
        chat_id: user.telegram_chat_id,
        text: request.plaintext
      )
    end
  end

  def show; end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_request
    @request = Request.find(params[:id])
  end
end
