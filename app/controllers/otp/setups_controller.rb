# frozen_string_literal: true

module Otp
  class SetupsController < ApplicationController
    skip_before_action :ensure_otp_is_set_up
    before_action :redirect_if_otp_is_already_set_up

    layout 'clearance'

    def new; end

    def create
      if current_user.authenticate_otp(otp_params[:otp], drift: 30)
        current_user.otp_enabled = true
        current_user.save!
        session[:otp_verified_for_user] = current_user.id

        redirect_back_or dashboard_path
      else
        flash.now[:error] = I18n.t('sessions.errors.otp_incorrect')
        render 'new'
      end
    end

    private

    def redirect_if_otp_is_already_set_up
      redirect_to dashboard_path if current_user.otp_enabled?
    end

    def otp_params
      params.require(:setup).permit(:otp)
    end
  end
end
