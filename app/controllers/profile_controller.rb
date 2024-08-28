# frozen_string_literal: true

class ProfileController < ApplicationController
  before_action :business_plans

  def index; end

  def create_user
    password = SecureRandom.alphanumeric(20)
    user = User.new(user_params.merge(password: password, organizations: [@organization]))
    if user.save
      redirect_to organization_profile_path(@organization), flash: { success: I18n.t('profile.user.created_successfully') }
    else
      redirect_to organization_profile_path(@organization), flash: { error: user.errors.full_messages.join(' ') }
    end
  end

  def upgrade_business_plan
    @organization.business_plan.update(valid_from: nil, valid_until: nil)
    business_plan = BusinessPlan.find(upgrade_business_plan_params[:business_plan_id])
    business_plan.update(valid_from: Time.current, valid_until: 1.year.from_now)
    @organization.business_plan = business_plan
    @organization.upgraded_business_plan_at = Time.current

    if @organization.save
      redirect_to organization_profile_path(@organization), flash: { success: I18n.t('profile.business_plan.updated_successfully') }
    else
      redirect_to organization_profile_path(@organization), flash: { error: @organization.errors.full_messages.join(' ') }
    end
  end

  private

  def user_params
    params.require(:user).permit(%i[first_name last_name email])
  end

  def upgrade_business_plan_params
    params.require(:profile).permit(:business_plan_id)
  end

  def business_plans
    @business_plans ||= BusinessPlan.order(:price_per_month)
  end
end
