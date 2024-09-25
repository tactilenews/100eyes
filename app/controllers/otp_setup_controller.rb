# frozen_string_literal: true

class OtpSetupController < ApplicationController
  skip_before_action :require_otp_setup, :user_permitted?, :set_organization
  before_action :redirect_if_set_up

  layout 'minimal'

  def show; end

  def create
    if current_user.authenticate_otp(otp_params[:otp], drift: 30)
      current_user.otp_enabled = true
      current_user.save!
      session[:otp_verified_for_user] = current_user.id

      redirect_to redirect_path
    else
      flash.now[:error] = I18n.t('sessions.errors.otp_incorrect')
      render :show, status: :unauthorized
    end
  end

  private

  def redirect_if_set_up
    redirect_to redirect_path if current_user.otp_enabled?
  end

  def otp_params
    params.require(:setup).permit(:otp)
  end
end
