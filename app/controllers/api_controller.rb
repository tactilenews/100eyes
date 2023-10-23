# frozen_string_literal: true

class ApiController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token
  before_action :authorize_api_access, :contributor

  def show
    if contributor
      render json: { status: 'ok', data: { first_name: contributor.first_name, external_id: contributor.external_id } }, status: :ok
    else
      render json: { status: 'error', message: 'Not found' }, status: :not_found
    end
  end

  def create
    if contributor
      render_json_contributor
      return
    end
    contributor = Contributor.new(onboard_params.merge(data_processing_consented_at: Time.current, external_id: external_id))

    if contributor.save
      render_json_contributor
    else
      render json: { status: 'error', message: contributor.errors.full_messages.join(' ') }, status: :unprocessable_entity
    end
  end

  def current_request
    if contributor
      current_request = contributor.active_request
      render json: {
        status: 'ok',
        data: {
          id: current_request.id,
          personalized_text: current_request.personalized_text(contributor),
          contributor_replies_count: contributor.replies.where(request_id: current_request.id).count
        }
      }, status: :ok
    else
      render json: { status: 'error', message: 'Not found' }, status: :not_found
    end
  end

  def messages
    if contributor
      message = Message.new(
        request: contributor.active_request,
        text: messages_params[:text],
        sender: contributor
      )
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(messages_params)),
        filename: 'api.json',
        content_type: 'application/json'
      )

      if message.save!
        render json: { status: 'ok', data: { id: message.id, text: message.text } }, status: :created
      else
        render json: { status: 'error', message: 'Record could not be created' }, status: :unprocessable_entity
      end
    else
      render json: { status: 'error', message: 'Not found' }, status: :not_found
    end
  end

  private

  def contributor
    @contributor ||= Contributor.find_by(external_id: external_id)
  end

  def authorize_api_access
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, Setting.api_token)
    end
  end

  def external_id
    request.headers['X-100eyes-External-Id']
  end

  def onboard_params
    params.permit(:first_name, :external_channel)
  end

  def messages_params
    params.permit(:text)
  end

  def render_json_contributor
    render json: {
      status: 'ok',
      data: { id: contributor.id,
              first_name: contributor.first_name,
              external_id: contributor.external_id,
              external_channel: contributor.external_channel }
    }, status: :created
  end
end
