# frozen_string_literal: true

class ApiController < ApplicationController
  skip_before_action :require_login
  before_action :authorize_api_access

  def show
    contributor = Contributor.find_by(external_id: external_id)

    unless contributor
      render json: { status: 'error', message: 'Not found' }, status: :not_found
      return
    end

    render json: { status: 'ok', data: { first_name: contributor.first_name, external_id: contributor.external_id } }, status: :ok
  end

  def create
    contributor = Contributor.find_by(external_id: external_id)
    if contributor
      render json: {
        status: 'ok',
        data: { id: contributor.id,
                first_name: contributor.first_name,
                external_id: contributor.external_id }
      }, status: :created
      return
    end

    contributor = Contributor.new(onboard_params.merge(data_processing_consented_at: Time.current, external_id: external_id))

    if contributor.save!
      render json: {
        status: 'ok',
        data: { id: contributor.id,
                first_name: contributor.first_name,
                external_id: contributor.external_id }
      }, status: :created
    else
      render json: { status: 'error', message: 'Record could not be created' }, status: :unprocessable_entity
    end
  end

  private

  def authorize_api_access
    authenticate_or_request_with_http_token do |token, _options|
      ActiveSupport::SecurityUtils.secure_compare(token, Setting.api_token)
    end
  end

  def external_id
    request.headers['X-100eyes-External-Id']
  end

  def onboard_params
    params.permit(:first_name)
  end
end
