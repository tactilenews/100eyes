# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[update destroy show message]

  def message
    request = user.active_request
    render(plain: 'No active request for this user', status: :bad_request) and return unless request

    text = message_params[:text]
    message = Message.create!(text: text, request: request, recipient: user, sender: nil)
    redirect_to message.chat_message_link, flash: { success: I18n.t('user.message-send', name: user.name) }
  end

  def index
    @users = User.all
  end

  def show; end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to @user, flash: { success: I18n.t('user.success') }
    else
      render :new
    end
  end

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
    params.require(:user).permit(:note, :first_name, :last_name, :email, :phone, :street, :zip_code, :city)
  end

  def message_params
    params.require(:message).permit(:text)
  end

  attr_reader :user
end
