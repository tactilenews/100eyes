# frozen_string_literal: true

class SettingsController < ApplicationController
  def index; end

  # rubocop:disable Metrics/AbcSize
  def update
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

  def settings_channel_param
    params.require(:setting).permit(channels: Setting.channels.keys.map(&:to_sym).map do |key|
                                                { key => %i[allow_onboarding configured] }
                                              end)
  end
end
