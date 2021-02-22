# frozen_string_literal: true

module Onboarding
  class ChannelController < ApplicationController
    include JwtHelper

    skip_before_action :require_login
    before_action -> { verify_onboarding_jwt(jwt_param) }

    layout 'onboarding'

    def show
      @contributor = Contributor.new
    end

    def create
      # We handle an onbaording request for a contributor that
      # already exists in the exact same way as a successful
      # onboarding so that we don't disclose wether someone
      # is a contributor.
      if contributor_exists?
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

    def contributor_exists?
      # Instead of checking just for uniqueness
      # we do a full record validation and check
      # for the presence of the `taken` error. This
      # is necessary as custom validators may perform
      # additional normalization.
      contributor = Contributor.new(attr_name => attr_value)
      contributor.valid?

      contributor.errors.details[attr_name].pluck(:error).include?(:taken)
    end

    def attr_value
      contributor_params[attr_name]
    end

    def contributor_params
      params.require(:contributor).permit(:first_name, :last_name, attr_name)
    end

    def default_url_options
      super.merge(jwt: jwt_param)
    end

    def redirect_to_success
      redirect_to onboarding_success_path(jwt: nil)
    end

    def redirect_to_failure
      redirect_to onboarding_path
    end

    def jwt_param
      params.require(:jwt)
    end
  end
end
