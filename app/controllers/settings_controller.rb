# frozen_string_literal: true

class SettingsController < ApplicationController
  def index; end

  def update
    settings_params.each_key do |key|
      Setting.send("#{key}=", settings_params[key].strip) unless settings_params[key].nil?
    end

    settings_files_params.each_key do |key|
      tempfile = settings_files_params[key]
      next if tempfile.nil?

      blob = ActiveStorage::Blob.create_and_upload!(io: tempfile, filename: tempfile.original_filename)
      Setting.send("#{key}=", blob)
    end

    flash[:success] = I18n.t('settings.success')
    redirect_to settings_url
  end

  private

  def settings_files_params
    params.require(:setting_files).permit(
      :onboarding_logo,
      :onboarding_hero
    )
  end

  def settings_params
    params.require(:setting).permit(
      :onboarding_ask_for_additional_consent,
      :onboarding_additional_consent_heading,
      :onboarding_additional_consent_text,
      :project_name,
      :onboarding_title,
      :onboarding_byline,
      :onboarding_success_heading,
      :onboarding_success_text,
      :onboarding_unauthorized_heading,
      :onboarding_unauthorized_text,
      :onboarding_page,
      :onboarding_data_protection_link,
      :onboarding_imprint_link,
      :signal_unknown_content_message,
      :telegram_unknown_content_message,
      :telegram_contributor_not_found_message,
      :threema_unknown_content_message
    )
  end
end
