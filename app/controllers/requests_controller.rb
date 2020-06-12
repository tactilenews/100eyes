# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_request, only: %i[show show_user_messages]
  before_action :set_user, only: %i[show_user_messages]

  def index
    @requests = Request.eager_load(:messages)
  end

  def show
    @message_groups = @request.messages_by_user
  end

  def create
    @request = Request.new(request_params)
    if @request.save
      redirect_to @request, flash: { success: I18n.t('request.success') }
    else
      render :new
    end
  end

  def new
    @request = Request.new
  end

  def show_user_messages
    @chat_messages = @user.conversation_about(@request)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_request
    @request = Request.find(params[:id])
  end

  def request_params
    params.require(:request).permit(:title, :text, hints: [])
  end
end
