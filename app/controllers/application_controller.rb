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
        redirect_to organizations_path
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

  def set_organization
    organization = Organization.find(params[:organization_id]) if params[:organization_id].present?
    user_permitted?(organization)
    @organization = organization
  rescue ActiveRecord::RecordNotFound
    raise ActionController::RoutingError, 'Not Found'
  end

  def user_permitted?(organization)
    raise ActionController::RoutingError, 'Not Found' unless current_user.admin? || organization.in?(current_user.organizations)
  end
end
