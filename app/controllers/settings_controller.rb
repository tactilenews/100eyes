# frozen_string_literal: true

class SettingsController < ApplicationController
  def index; end

  def update
    settings_params.each do |key, value|
      if value.respond_to? :keys
        value.each_key do |locale_value|
          setting_record = Setting.find_by(var: key)
          setting_record.update!(locale_value.to_sym => value[locale_value].strip)
        end
      else
        Setting.send("#{key}=", value.strip) unless value.nil?
      end
    end

    settings_files_params.each do |key, tempfile|
      next if tempfile.nil?

      blob = ActiveStorage::Blob.create_and_upload!(io: tempfile, filename: tempfile.original_filename)
      Setting.send("#{key}=", blob)
    end

    flash[:success] = I18n.t('settings.success')
    redirect_to settings_url
  end

  private

  def settings_files_params
    params.require(:setting).permit(
      :onboarding_logo,
      :onboarding_hero
    )
  end

  def settings_params
    params.require(:setting).permit(
      :onboarding_ask_for_additional_consent,
      :project_name,
      :onboarding_byline,
      :signal_unknown_content_message,
      :telegram_unknown_content_message,
      :telegram_contributor_not_found_message,
      :threema_unknown_content_message,
      onboarding_additional_consent_heading: [available_locale_params],
      onboarding_additional_consent_text: [available_locale_params],
      onboarding_unauthorized_heading: [available_locale_params],
      onboarding_unauthorized_text: [available_locale_params],
      onboarding_data_protection_link: [available_locale_params],
      onboarding_imprint_link: [available_locale_params],
      onboarding_title: [available_locale_params],
      onboarding_page: [available_locale_params],
      onboarding_success_heading: [available_locale_params],
      onboarding_success_text: [available_locale_params]
    )
  end

  def available_locale_params
    I18n.available_locales.map do |locale|
      [:"value_#{locale}"]
    end.flatten
  end
end
