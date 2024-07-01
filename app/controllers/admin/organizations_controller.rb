# frozen_string_literal: true

module Admin
  class OrganizationsController < Admin::ApplicationController
    def edit
      resource = requested_resource
      resource = obfuscate_encrypted_attrs(resource)
      render locals: {
        page: Administrate::Page::Form.new(dashboard, resource)
      }
    end

    def update
      organization = Organization.find(update_params[:id])
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
                    organization: %i[id business_plan_id upgrade_discount contact_person_id name
                                     threemarb_api_identity threemarb_api_secret threemarb_private
                                     twilio_account_sid twilio_api_key_sid twilio_api_key_secret])
    end

    def obfuscate_encrypted_attrs(resource)
      resource.threemarb_api_secret = resource.encrypted_threemarb_api_secret
      resource.threemarb_private = resource.encrypted_threemarb_private
      resource.twilio_api_key_secret = resource.encrypted_twilio_api_key_secret
      resource
    end
  end
end
