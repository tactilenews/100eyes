# frozen_string_literal: true

class ProfileController < ApplicationController
  def index
    @organization = current_user.admin? ? Organization.last : current_user.organization
    @business_plans = BusinessPlan.order(:price_per_month)
  end

  def create_user
    organization = current_user.organization
    password = SecureRandom.alphanumeric(20)
    user = User.new(user_params[:user].merge(password: password, organization: organization))
    redirect_to profile_path, flash: { success: I18n.t('profile.user.created_successfully') } if user.save
  end

  def upgrade_business_plan
    organization = current_user.organization
    business_plan = BusinessPlan.find(upgrade_business_plan_params[:business_plan_id])
    business_plan.update(valid_from: Time.current, valid_until: organization.business_plan.valid_until)
    organization.business_plan = business_plan

    redirect_to profile_path, flash: { success: I18n.t('profile.business_plan.updated_successfully') } if organization.save
  end

  private

  def user_params
    params.require(:profile).permit(user: %i[first_name last_name email])
  end

  def upgrade_business_plan_params
    params.require(:profile).permit(:business_plan_id)
  end
end
