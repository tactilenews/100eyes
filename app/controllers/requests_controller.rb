# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_request, only: %i[show show_user_messages notifications]
  before_action :set_user, only: %i[show_user_messages]
  before_action :notifications_params, only: :notifications

  def index
    @requests = Request.eager_load(:messages)
  end

  def show
    @message_groups = @request.messages_by_user
  end

  def create
    @request = Request.new(request_params)
    if @request.save
      redirect_to @request, flash: { success: I18n.t('request.success', count: @request.stats[:counts][:recipients]) }
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

  def notifications
    last_updated_at = Time.zone.parse(params[:last_updated_at])
    message_count = @request.replies.where('created_at >= ?', last_updated_at).count
    render json: { message_count: message_count }
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_request
    @request = Request.find(params[:id])
  end

  def request_params
    params.require(:request).permit(:title, :text, :tag_list, hints: [])
  end

  def notifications_params
    params.require(:last_updated_at)
  end
end
