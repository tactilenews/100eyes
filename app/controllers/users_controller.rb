# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[update destroy show message]

  def message
    request = Request.active_request
    render(plain: 'No active request for this user', status: :bad_request) and return unless request

    message = message_params[:text]
    Telegram.bots[Rails.configuration.bot_id].send_message(
      chat_id: user.telegram_chat_id,
      text: message
    )
    if user.email
      QuestionMailer
        .with(message: message, to: user.email)
        .new_message_email
        .deliver_later
    end
    last_message = request.messages.where(user: user).reorder(created_at: :desc).first
    redirect_to user_request_path(user, request, anchor: "chat-row-#{last_message.id}"), flash: { success: I18n.t('user.message-send', name: @user.name) }
  end

  def index
    @users = User.all
  end

  def show; end

  def update
    if @user.update(user_params)
      redirect_to user_url, flash: { success: I18n.t('user.saved', name: @user.name) }
    else
      flash[:error] = I18n.t('user.invalid', name: @user.name)
      render :show
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: 'User was successfully destroyed.'
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:note, :name, :email)
  end

  def message_params
    params.require(:message).permit(:text)
  end

  attr_reader :user
end
