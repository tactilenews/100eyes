# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Clearance::Controller
  before_action :require_login, :require_otp_setup
  set_current_tenant_through_filter
  before_action :set_organization

  def require_otp_setup
    redirect_to otp_setup_path if signed_in? && !current_user.otp_enabled?
  end

  def sign_in(user)
    delete_otp_session_variables

    super(user) do |status|
      if status.success?
        redirect_to current_user.admin? ? admin_root_path : dashboard_path(user.organization)
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

  def set_organization
    return unless signed_in?

    @organization = Organization.friendly.find(params[:organization])
    if current_user.admin? || organization.eql?(current_user.organization)
      set_current_tenant(current_user.organization)
    else
      redirect_to dashboard_path(current_user.organization)
    end
  end
end
