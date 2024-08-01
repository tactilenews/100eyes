# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Clearance::Controller
  before_action :require_login, :require_otp_setup
  before_action :set_organization

  def require_otp_setup
    redirect_to otp_setup_path if signed_in? && !current_user.otp_enabled?
  end

  def sign_in(user)
    delete_otp_session_variables

    super(user) do |status|
      if status.success?
        redirect_to dashboard_path
      else
        flash.now.alert = status.failure_message
        render template: 'sessions/new', status: :unauthorized
      end
    end
  end

  def sign_out
    delete_otp_session_variables
    super
  end

  def delete_otp_session_variables
    session.delete(:otp_user_id)
    session.delete(:otp_time)
  end

  private

  # TODO: Remove this when every use of @organization is changed to use the helper method
  def set_organization
    organization
  end

  # TODO: Remove the singleton usage when every route is scoped by the organization
  #
  # Helper method returning the memoized organization context helps to prevent prop drilling
  #
  def organization
    return @organization if defined? @organization

    if params[:organization_id].present?
      @organization = Organization.find(params[:organization_id])
    else
      @organization = Organization.singleton
    end
  end
  helper_method :organization
end
