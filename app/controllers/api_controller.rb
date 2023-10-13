# frozen_string_literal: true

class ApiController < ApplicationController
  skip_before_action :require_login

  def contributor
    contributor = Contributor.find_by(external_id: contributor_params[:external_id])
    return head :not_found unless contributor

    render json: { first_name: contributor.first_name, external_id: contributor.external_id }
  end

  def onboard
    contributor = Contributor.find_or_initialize_by(external_id: onboard_params[:external_id])
    contributor.first_name = onboard_params[:first_name]
    contributor.data_processing_consented_at = Time.current if contributor.data_processing_consented_at.blank?

    if contributor.save!
      render json: { id: contributor.id }
    else
      head :unprocessable_entity
    end
  end

  private

  def contributor_params
    params.permit(:external_id)
  end

  def onboard_params
    params.permit(:external_id, :first_name)
  end
end
