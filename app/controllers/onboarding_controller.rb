# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate
  layout 'onboarding'

  def index
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to onboarding_success_path
    else
      render :index
    end
  end

  def success; end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end
end
