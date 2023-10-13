# frozen_string_literal: true

class ApiController < ApplicationController
  skip_before_action :require_login
  before_action :authorize_api_access

  def contributor
    contributor = Contributor.find_by(external_id: contributor_params[:external_id])
    return head :not_found unless contributor

    render json: { first_name: contributor.first_name, external_id: contributor.external_id }
  end

  def onboard
    contributor = Contributor.find_by(external_id: onboard_params[:external_id])
    if contributor
      render json: { id: contributor.id }
      return
    end

    contributor = Contributor.new(onboard_params.merge(data_processing_consented_at: Time.current))

    if contributor.save!
      render json: { id: contributor.id }
    else
      head :unprocessable_entity
    end
  end

  private

  def authorize_api_access
    headers = request.headers
    jwt = headers['Authorization'].split.last if headers['Authorization'].present?

    JsonWebToken.decode(jwt)
  rescue JWT::DecodeError
    head :unauthorized
  end

  def contributor_params
    params.permit(:external_id)
  end

  def onboard_params
    params.permit(:external_id, :first_name)
  end
end
