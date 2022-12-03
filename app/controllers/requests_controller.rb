# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_request, only: %i[show show_contributor_messages notifications]
  before_action :set_contributor, only: %i[show_contributor_messages]
  before_action :notifications_params, only: :notifications

  def index
    @requests = Request.preload(messages: :sender)
                       .includes(messages: :files)
                       .eager_load(:messages)
  end

  def show
    @message_groups = @request.messages_by_contributor
  end

  def create
    resize_image_files if request_params[:files].present?
    @request = Request.new(request_params.merge(user: current_user))
    if @request.save
      redirect_to @request, flash: { success: I18n.t('request.success', count: @request.stats[:counts][:recipients]) }
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new
    @request = Request.new
  end

  def show_contributor_messages
    @chat_messages = @contributor.conversation_about(@request)
  end

  def notifications
    last_updated_at = Time.zone.parse(params[:last_updated_at])
    message_count = @request.replies.where('created_at >= ?', last_updated_at).count
    render json: { message_count: message_count }
  end

  private

  def set_contributor
    @contributor = Contributor.find(params[:contributor_id])
  end

  def set_request
    @request = Request.find(params[:id])
  end

  def request_params
    params.require(:request).permit(:title, :text, :tag_list, files: [])
  end

  def notifications_params
    params.require(:last_updated_at)
  end

  def resize_image_files
    return if Rails.env.test?

    paths = request_params[:files].map { |file| file.tempfile.path }
    paths.each do |path|
      ImageProcessing::MiniMagick.source(path)
                                 .resize_to_limit(1200, 1200)
                                 .call(destination: path)
    end
  end
end
