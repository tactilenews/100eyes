# frozen_string_literal: true

class OrganizationsController < ApplicationController
  def index; end

  def update
    if @organization.update!(organizations_params)
      flash[:success] = I18n.t('settings.success')
      redirect_to settings_path
    else
      render :index, status: :unprocessable_entity
    end
  end

  def organizations_params
    params.require(:organization).permit(
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
end
