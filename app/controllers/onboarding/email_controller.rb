# frozen_string_literal: true

module Onboarding
  class EmailController < ApplicationController
    include JwtHelper

    skip_before_action :require_login
    before_action -> { verify_onboarding_jwt(jwt_param) }

    layout 'onboarding'

    def create
      # Ensure information on registered contributors is never
      # disclosed during onboarding
      if Contributor.email_taken?(contributor_params[:email])
        invalidate_jwt(jwt_param)
        return redirect_to_success
      end

      @contributor = Contributor.new(contributor_params)

      if @contributor.save
        invalidate_jwt(jwt_param)
        return redirect_to_success
      end

      redirect_to_failure
    end

    private

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
