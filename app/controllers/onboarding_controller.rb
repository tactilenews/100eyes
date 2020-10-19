# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate
  before_action :verify_token, except: %i[create_invite_url unauthorized]

  layout 'onboarding'

  def index
    @jwt = jwt_param
    @user = User.new
  end

  def create
    # Ensure information on registered users is never
    # disclosed during onboarding
    return redirect_to_success if User.email_taken?(user_params[:email])

    @user = User.new(user_params)
    if @user.save
      JsonWebToken.create(invalidated_jti: params[:jwt])
      return redirect_to_success
    end

    render :index
  end

  def success; end

  def unauthorized; end

  def create_invite_url
    payload = SecureRandom.base64(16)
    jwt = JsonWebToken.encode(payload)
    render json: { url: onboarding_url(jwt: jwt) }
  end

  private

  def redirect_to_success
    redirect_to onboarding_success_path(jwt: jwt_param)
  end

  def verify_token
    invalidated_jti = JsonWebToken.where(invalidated_jti: jwt_param)
    raise ActionController::BadRequest if invalidated_jti.exists?

    JsonWebToken.decode(jwt_param)
  rescue ActionController::BadRequest
    redirect_to onboarding_unauthorized_path
  rescue JWT::DecodeError
    redirect_to onboarding_unauthorized_path
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def jwt_param
    params.require(:jwt)
  end
end
