# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate
  before_action :verify_token

  layout 'onboarding'

  def index
    @token = token_param
    @user = User.new
  end

  def create
    # Ensure information on registered users is never
    # disclosed during onboarding
    return redirect_to_success if User.email_taken?(user_params[:email])

    @user = User.new(user_params)
    return redirect_to_success if @user.save

    render :index
  end

  def success; end

  private

  def redirect_to_success
    redirect_to onboarding_success_path(token: token_param)
  end

  def verify_token
    raise ActionController::BadRequest unless token_param == Setting.onboarding_token
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def token_param
    params.require(:token)
  end
end
