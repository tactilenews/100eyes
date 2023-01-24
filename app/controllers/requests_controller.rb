# frozen_string_literal: true

class RequestsController < ApplicationController
  before_action :set_request, only: %i[show show_contributor_messages edit update notifications]
  before_action :set_contributor, only: %i[show_contributor_messages]
  before_action :notifications_params, only: :notifications
  before_action :disallow_edit, only: %i[edit update]

  def index
    @filter = filter_param
    @sent_requests_count = Request.include_associations.sent.count
    @planned_requests_count = Request.include_associations.planned.count
    @requests = filtered_requests.page(params[:page])
  end

  def show
    @message_groups = @request.messages_by_contributor
  end

  def create
    resize_image_files if request_params[:files].present?
    @request = Request.new(request_params.merge(user: current_user))
    if @request.save
      if @request.planned?
        redirect_to requests_path(filter: :planned), flash: {
          success: I18n.t('request.schedule_request_success',
                          count: Contributor.active.with_tags(@request.tag_list).count,
                          scheduled_datetime: I18n.l(@request.schedule_send_for, format: :long))
        }
      else
        redirect_to @request, flash: { success: I18n.t('request.success', count: @request.stats[:counts][:recipients]) }
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new
    @request = Request.new
  end

  def edit; end

  def update
    if @request.update(request_params)
      if @request.planned?
        redirect_to requests_path(filter: :planned), flash: {
          success: I18n.t('request.schedule_request_success',
                          count: Contributor.active.with_tags(@request.tag_list).count,
                          scheduled_datetime: I18n.l(@request.schedule_send_for, format: :long))
        }
      else
        redirect_to @request, flash: { success: I18n.t('request.success', count: @request.stats[:counts][:recipients]) }
      end
    else
      render :edit, status: :unprocessable_entity
    end
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
    params.require(:request).permit(:title, :text, :tag_list, :schedule_send_for, files: [])
  end

  def notifications_params
    params.require(:last_updated_at)
  end

  def resize_image_files
    return if Rails.env.test?

    paths = request_params[:files].reject { |file| file.content_type.match?(%r{image/svg}) }.map { |file| file.tempfile.path }
    paths.each do |path|
      ImageProcessing::MiniMagick.source(path)
                                 .resize_to_limit(1200, 1200)
                                 .call(destination: path)
    end
  end

  def disallow_edit
    return if @request.planned?

    redirect_to requests_path, flash: { error: I18n.t('request.editing_disallowed') }
  end

  def filter_param
    value = params.permit(:filter)[:filter]&.to_sym

    return :sent unless %i[sent planned].include?(value)

    value
  end

  def filtered_requests
    @filter == :planned ? Request.reorder(schedule_send_for: :desc).include_associations.planned : Request.include_associations.sent
  end
end
