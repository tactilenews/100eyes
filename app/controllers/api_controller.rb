# frozen_string_literal: true

class ApiController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token
  before_action :contributor
  before_action :authorize_api_access, except: :direct_message
  before_action :authenciate_user, only: :direct_message
  rescue_from JWT::DecodeError, with: :render_unauthorized

  def show
    if contributor
      render_json_show_contributor
    else
      render json: { status: 'error', message: 'Not found' }, status: :not_found
    end
  end

  def create
    if contributor
      render_json_created_contributor
      return
    end
    contributor = Contributor.new(onboard_params.merge(data_processing_consented_at: Time.current, external_id: external_id))

    if contributor.save
      render_json_created_contributor
    else
      render json: { status: 'error', message: contributor.errors.full_messages.join(' ') }, status: :unprocessable_entity
    end
  end

  def update
    if contributor
      if contributor.update(phone: update_contributor_params[:phone_number])
        render_json_updated_contributor
      else
        render json: { status: 'error', message: contributor.errors.full_messages.join(' ') }, status: :unprocessable_entity
      end
    else
      render_not_found
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
      render_not_found
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

  def direct_message
    if contributor
      message = Message.new(
        request: contributor.active_request,
        text: direct_message_params[:text],
        sender: current_user
      )
      message.raw_data.attach(
        io: StringIO.new(JSON.generate(direct_message_params)),
        filename: 'api.json',
        content_type: 'application/json'
      )

      if message.save!
        render json: { status: 'ok', data: { id: message.id, text: message.text } }, status: :created
      else
        render json: { status: 'error', message: 'Record could not be created' }, status: :unprocessable_entity
      end
    else
      render_not_found
    end
  end

  private

  attr_reader :current_user

  def contributor
    @contributor ||= Contributor.find_by(external_id: external_id)
  end

  def authorize_api_access
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, Setting.api_token)
    end
  end

  def authenciate_user
    decoded_token = JWT.decode(direct_message_params[:jwt], Setting.api_token, true, { algorithm: 'HS256' }).first.with_indifferent_access
    @current_user = User.find_by(email: decoded_token[:email], encrypted_password: decoded_token[:encrypted_password])
    render_not_found unless @current_user
  end

  def external_id
    request.headers['X-100eyes-External-Id']
  end

  def onboard_params
    params.permit(:first_name, :external_channel)
  end

  def update_contributor_params
    params.permit(:phone_number)
  end

  def messages_params
    params.permit(:text)
  end

  def direct_message_params
    params.permit(:text, :jwt)
  end

  def render_unauthorized
    render json: {
      status: 'error',
      message: 'Unauthorized'
    }, status: :unauthorized
  end

  def render_not_found
    render json: {
      status: 'error',
      message: 'Not found'
    }, status: :not_found
  end

  def render_json_created_contributor
    render json: {
      status: 'ok',
      data: {
        id: contributor.id,
        first_name: contributor.first_name,
        external_id: contributor.external_id,
        external_channel: contributor.external_channel
      }
    }, status: :created
  end

  def render_json_show_contributor
    render json: {
      status: 'ok',
      data: {
        first_name: contributor.first_name,
        external_id: contributor.external_id,
        active: contributor.active?
      }
    }, status: :ok
  end

  def render_json_updated_contributor
    render json: {
      status: 'ok',
      data: {
        id: contributor.id,
        first_name: contributor.first_name,
        external_id: contributor.external_id,
        phone_number: contributor.phone
      }
    }, status: :ok
  end
end
