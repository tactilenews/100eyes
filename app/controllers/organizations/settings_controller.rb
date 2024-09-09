# frozen_string_literal: true

module Organizations
  class SettingsController < ApplicationController
    def index; end

    def update
      if @organization.update!(organizations_params)
        flash[:success] = I18n.t('settings.success')
        redirect_to organization_settings_path(@organization)
      else
        render :index, status: :unprocessable_entity
      end
    end

    private

    def organizations_params
      params.require(:organization).permit(
        :project_name,
        :onboarding_logo,
        :onboarding_byline,
        :onboarding_hero,
        :onboarding_title,
        :onboarding_page,
        :onboarding_success_heading,
        :onboarding_success_text,
        :onboarding_unauthorized_heading,
        :onboarding_unauthorized_text,
        :signal_unknown_content_message,
        :telegram_unknown_content_message,
        :telegram_contributor_not_found_message,
        :threema_unknown_content_message
      )
    end
  end
end
