# frozen_string_literal: true

class ProfileController < ApplicationController
  def index
    @organization = current_user.organization
  end

  def create_user
    organization = current_user.organization
    password = SecureRandom.alphanumeric(20)
    user = User.new(user_params[:user].merge(password: password, organization: organization))
    redirect_to profile_path, flash: { success: I18n.t('profile.user.created_successfully') } if user.save
  end

  private

  def user_params
    params.require(:profile).permit(user: %i[first_name last_name email])
  end
end
