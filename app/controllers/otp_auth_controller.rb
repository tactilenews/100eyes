# frozen_string_literal: true

class OtpAuthController < ApplicationController
  skip_before_action :require_login
  skip_before_action :require_otp_setup
  before_action :redirect_if_signed_in, :redirect_unless_user_set, :reset_when_inactive

  layout 'minimal'

  def show; end

  def create
    if @user.authenticate_otp(params[:session][:otp], drift: 30) && @user.active?
      sign_in(@user)
    elsif @user.inactive?
      redirect_to sign_in_path, flash: { alert: I18n.t('sessions.errors.deactivated_user') }
    else
      flash.now.alert = I18n.t('sessions.errors.otp_incorrect')
      render :show, status: :unauthorized
    end
  end

  private

  def redirect_unless_user_set
    @user = User.find_by(id: session[:otp_user_id])

    redirect_to sign_in_path unless @user
  end

  def reset_when_inactive
    return unless session[:otp_start_time] <= 15.minutes.ago

    sign_out
    redirect_to sign_in_path
  end

  def redirect_if_signed_in
    redirect_to organizations_path if signed_in?
  end
end
