# frozen_string_literal: true

module Admin
  class OrganizationsController < Admin::ApplicationController
    def update
      organization = Organization.friendly.find(update_params[:id])
      organization.business_plan.update(valid_from: nil, valid_until: nil)
      business_plan = BusinessPlan.find(update_params[:organization][:business_plan_id])
      business_plan.update(valid_from: Time.current, valid_until: 1.year.from_now)
      organization.upgraded_business_plan_at =
        (Time.current if business_plan.price_per_month > organization.business_plan.price_per_month)
      if organization.update(update_params[:organization])
        redirect_to admin_organization_path(organization)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def update_params
      params.permit(:id,
                    organization: %i[id business_plan_id upgrade_discount contact_person_id name telegram_bot_api_key
                                     telegram_bot_username whats_app_server_phone_number])
    end
  end
end
