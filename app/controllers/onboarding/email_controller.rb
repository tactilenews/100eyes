# frozen_string_literal: true

module Onboarding
  class EmailController < ApplicationController
    skip_before_action :require_login
    before_action :verify_onboarding_jwt

    layout 'onboarding'

    def create
      # Ensure information on registered contributors is never
      # disclosed during onboarding
      if Contributor.email_taken?(contributor_params[:email])
        invalidate_jwt
        return redirect_to_success
      end

      @contributor = Contributor.new(contributor_params)

      if @contributor.save
        invalidate_jwt
        return redirect_to_success
      end

      redirect_to_failure
    end

    private

    def verify_onboarding_jwt
      invalidated_jwt = JsonWebToken.where(invalidated_jwt: jwt_param)
      raise ActionController::BadRequest if invalidated_jwt.exists?

      decoded_token = JsonWebToken.decode(jwt_param)

      raise ActionController::BadRequest if decoded_token.first['data']['action'] != 'onboarding'
    rescue StandardError
      render 'onboarding/unauthorized', status: :unauthorized
    end

    def invalidate_jwt
      JsonWebToken.create(invalidated_jwt: params[:jwt])
    end

    def redirect_to_success
      redirect_to onboarding_success_path
    end

    def redirect_to_failure
      redirect_to onboarding_path
    end

    def contributor_params
      params.require(:contributor).permit(:first_name, :last_name, :email)
    end

    def jwt_param
      params.require(:jwt)
    end
  end
end
