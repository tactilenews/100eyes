# frozen_string_literal: true

# TODO: Refactor to remove the need to disable rubocop
class RequestsController < ApplicationController
  before_action :set_request, except: %i[index create new]
  before_action :notifications_params, only: :notifications
  before_action :disallow_edit, only: %i[edit update]
  before_action :disallow_destroy, only: :destroy
  before_action :available_tags, only: %i[new edit]

  def index
    @filter = filter_param
    @sent_requests_count = @organization.requests.broadcasted.count
    @planned_requests_count = @organization.requests.planned.count
    @requests = filtered_requests.page(params[:page])
  end

  def show; end

  def create
    resize_image_files if request_params[:files].present?
    @request = @organization.requests.new(request_params.merge(user: current_user))
    if @request.save
      trigger_broadcast_and_redirect(@request)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def new
    @request = @organization.requests.new
  end

  def edit; end

  def update
    @request.files.purge_later if @request.files.attached? && request_params[:files].blank?
    if @request.update(request_params)
      trigger_broadcast_and_redirect(@request)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @request.destroy
      redirect_to organization_requests_url(@request.organization, filter: :planned),
                  flash: { notice: t('request.destroy.successful', request_title: @request.title) }
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def notifications
    last_updated_at = Time.zone.parse(params[:last_updated_at])
    message_count = @request.replies.where('created_at >= ?', last_updated_at).count
    render json: { message_count: message_count }
  end

  def messages_by_contributor
    @message_groups = @request.messages_by_contributor
    render(
      MessageGroups::MessageGroups.new(request: @request,
                                       message_groups: @message_groups), content_type: 'text/html'
    )
  end

  def stats
    stats = @request.stats
    metrics = [
      {
        value: stats[:counts][:contributors],
        total: stats[:counts][:recipients],
        label: I18n.t('components.request_metrics.contributors', count: stats[:counts][:contributors]),
        icon: 'single-03',
        data: { testid: 'unique-contributors-replied-ratio' }
      },
      {
        value: stats[:counts][:replies],
        label: I18n.t('components.request_metrics.replies', count: stats[:counts][:replies]),
        icon: 'a-chat',
        data: { testid: 'total-replies-count' }
      },
      {
        value: stats[:counts][:photos],
        label: I18n.t('components.request_metrics.photos', count: stats[:counts][:photos]),
        icon: 'camera',
        data: { testid: 'photos-count' }
      }
    ]
    render(InlineMetrics::InlineMetrics.new(metrics: metrics), content_type: 'text/html')
  end

  def generate_csv
    request_csv = Requests::GenerateCsvService.call(request_id: params[:id])
    send_data request_csv
  end

  private

  def set_request
    @request = @organization.requests.find(params[:id])
  end

  def available_tags
    @available_tags ||= @organization.contributors_tags_with_count.to_json
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

    redirect_to organization_requests_path(@request.organization), flash: { error: I18n.t('request.editing_disallowed') }
  end

  def disallow_destroy
    return if @request.planned?

    redirect_to organization_requests_path(@request.organization),
                flash: { error: I18n.t('request.destroy.broadcasted_request_unallowed', request_title: @request.title) }
  end

  def filter_param
    value = params.permit(:filter, :organization_id)[:filter]&.to_sym

    return :sent unless %i[sent planned].include?(value)

    value
  end

  def filtered_requests
    if @filter == :planned
      @organization.requests.planned.reorder(schedule_send_for: :desc).includes(:tags)
    else
      @organization.requests.broadcasted.includes(:tags)
    end
  end

  def trigger_broadcast_and_redirect(request)
    recipient_count = @request.organization.contributors.active.with_tags(request.tag_list).count
    run_at = request.trigger_broadcast
    if run_at
      redirect_to organization_requests_path(@organization, filter: :planned), flash: {
        success: I18n.t('request.schedule_request_success',
                        count: recipient_count,
                        scheduled_datetime: I18n.l(run_at, format: :long))
      }
    else
      redirect_to organization_request_path(@organization.id, request),
                  flash: { success: I18n.t('request.success', count: recipient_count) }
    end
  end
end
