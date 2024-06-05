# frozen_string_literal: true

class SettingsController < ApplicationController
  def index; end

  # rubocop:disable Metrics/AbcSize
  def update
    settings_params.each do |key, value|
      Setting.send("#{key}=", value.strip) unless value.nil?
    end

    settings_files_params.each do |key, tempfile|
      next if tempfile.nil?

      blob = ActiveStorage::Blob.create_and_upload!(io: tempfile, filename: tempfile.original_filename)
      Setting.send("#{key}=", blob)
    end

    settings_channel_param.each do |key, values_params|
      values_hash = values_params.to_h.each_with_object({}) do |(k, value), accumlator|
        accumlator[k.to_sym] = {
          configured: ActiveModel::Type::Boolean.new.cast(value[:configured]),
          allow_onboarding: ActiveModel::Type::Boolean.new.cast(value[:allow_onboarding])
        }
      end
      Setting.send("#{key}=", values_hash)
    end

    flash[:success] = I18n.t('settings.success')
    redirect_to settings_url
  end
  # rubocop:enable Metrics/AbcSize

  private

  def settings_files_params
    params.require(:setting).permit(
      :onboarding_logo,
      :onboarding_hero,
      :channel_image
    )
  end

  def settings_params
    params.require(:setting).permit(
      :onboarding_ask_for_additional_consent,
      :onboarding_additional_consent_heading,
      :onboarding_additional_consent_text,
      :onboarding_data_processing_consent_additional_info,
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
      :threema_unknown_content_message,
      :about
    )
  end

  def settings_channel_param
    params.require(:setting).permit(channels: Setting.channels.keys.map(&:to_sym).map do |key|
                                                { key => %i[allow_onboarding configured] }
                                              end)
  end
end
