# frozen_string_literal: true

BOT_ID = (ENV['BOT'] || :default).to_sym

class RequestsController < ApplicationController
  before_action :set_user, only: %i[show]
  before_action :set_request, only: %i[show]

  def new; end

  def create
    question = params[:question]
    Request.create!(text: question)
    QuestionMailer
      .with(question: question)
      .new_question_email
      .deliver_later
    User.where.not(telegram_chat_id: nil).find_each do |user|
      Telegram.bots[BOT_ID].send_message(chat_id: user.telegram_chat_id, text: question)
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
