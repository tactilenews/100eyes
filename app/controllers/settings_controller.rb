# frozen_string_literal: true

class SettingsController < ApplicationController
  def index; end

  def update
    settings_params.each_key do |key|
      Setting.send("#{key}=", settings_params[key].strip) unless settings_params[key].nil?
    end

    flash[:success] = I18n.t('settings.success')
    render :index
  end

  private

  def settings_params
    params.require(:setting).permit(
      :project_name,
      :onboarding_logo,
      :onboarding_hero,
      :onboarding_title,
      :onboarding_success_heading,
      :onboarding_success_text,
      :onboarding_unauthorized_heading,
      :onboarding_unauthorized_text,
      :onboarding_page,
      :telegram_unknown_content_message,
      :telegram_who_are_you_message
    )
  end
end
