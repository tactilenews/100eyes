# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_request, only: %i[show show_user_messages]
  before_action :set_user, only: %i[show_user_messages]

  def show
    @replies = @request.replies
  end

  def create
    request = Request.create!(
      title: params.fetch(:title),
      text: params.fetch(:text),
      hints: params.fetch(:hints, [])
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

  def show_user_messages
    @chat_messages = [@request] + @user.replies_for_request(@request)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_request
    @request = Request.find(params[:id])
  end
end
