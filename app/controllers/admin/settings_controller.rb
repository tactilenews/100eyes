# frozen_string_literal: true

module Admin
  class SettingsController < ApplicationController
    def index; end

    def create
      setting_params.keys.each do |key|
        Setting.send("#{key}=", setting_params[key].strip) unless setting_params[key].nil?
      end

      flash[:success] = I18n.t('settings.success')
      render :index
    end

    private

    def setting_params
      params.require(:setting).permit(
        :project_name,
        :onboarding_token,
        :onboarding_logo,
        :onboarding_hero,
        :onboarding_title,
        :onboarding_page,
        :telegram_welcome_message,
        :telegram_unknown_content_message
      )
    end
  end
end
