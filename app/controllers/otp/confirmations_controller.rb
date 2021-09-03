# frozen_string_literal: true

module Otp
  class ConfirmationsController < ApplicationController
    skip_before_action :ensure_otp_is_verified
    before_action :redirect_if_otp_is_already_verified

    layout 'clearance'

    def new; end

    def create
      if current_user.authenticate_otp(otp_params[:otp], drift: 30)
        session[:otp_verified_for_user] = current_user.id
        redirect_back_or dashboard_path
      else
        flash.now[:error] = I18n.t('sessions.errors.otp_incorrect')
        render 'new'
      end
    end

    private

    def redirect_if_otp_is_already_verified
      redirect_to dashboard_path if session[:otp_verified_for_user] == current_user.id
    end

    def otp_params
      params.require(:session).permit(:otp)
    end
  end
end
