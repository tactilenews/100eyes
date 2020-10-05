# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate

  layout 'onboarding'

  def index
    @user = User.new
  end

  def create
    # Ensure information on registered users is never
    # disclosed during onboarding
    @user = User.find_by(email: user_params[:email])
    return redirect_to onboarding_success_path if @user

    @user = User.new(user_params)
    return redirect_to onboarding_success_path if @user.save

    render :index
  end

  def success; end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
