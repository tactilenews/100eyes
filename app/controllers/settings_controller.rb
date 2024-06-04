# frozen_string_literal: true

class SettingsController < ApplicationController
  def index; end

  def update
    settings_channel_param.each do |key, values_params|
      values_hash = values_params.to_h.transform_values { |value| ActiveModel::Type::Boolean.new.cast(value) }
      Setting.send("#{key}=", values_hash)
    end

    flash[:success] = I18n.t('settings.success')
    redirect_to settings_url
  end

  private

  def settings_channel_param
    params.require(:setting).permit(channels: {})
  end
end
