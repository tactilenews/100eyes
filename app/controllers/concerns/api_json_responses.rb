# frozen_string_literal: true

module ApiJsonResponses
  extend ActiveSupport::Concern

  private

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

  def render_creation_failed
    render json: {
      status: 'error',
      message: 'Record could not be created'
    }, status: :unprocessable_entity
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

  def render_created_message(message)
    render json: {
      status: 'ok',
      data: {
        id: message.id,
        text: message.text
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
