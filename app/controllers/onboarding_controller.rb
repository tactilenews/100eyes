# frozen_string_literal: true

class OnboardingController < ApplicationController
  include JwtHelper

  skip_before_action :require_login
  before_action -> { verify_onboarding_jwt(jwt_param) }, except: :success

  layout 'onboarding'

  def index
    @jwt = jwt_param
    @contributor = Contributor.new
  end

  def success; end

  private

  def default_url_options
    super.merge(jwt: @jwt)
  end

  def jwt_param
    params.require(:jwt)
  end
end
