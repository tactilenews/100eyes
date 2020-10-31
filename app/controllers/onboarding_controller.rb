# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate, except: :create_invite_url
  before_action :verify_jwt, except: :create_invite_url

  layout 'onboarding'

  def index
    @jwt = jwt_param
    @user = User.new
  end

  def create
    # Ensure information on registered users is never
    # disclosed during onboarding
    return redirect_to_success && invalidate_jwt if User.email_taken?(user_params[:email])

    @user = User.new(user_params)
    return redirect_to_success && invalidate_jwt if @user.save

    render :index
  end

  def success; end

  def create_invite_url
    payload = SecureRandom.base64(16)
    jwt = JsonWebToken.encode(payload)
    render json: { url: onboarding_url(jwt: jwt) }
  end

  private

  def redirect_to_success
    redirect_to onboarding_success_path
  end

  def verify_jwt
    invalidated_jwt = JsonWebToken.where(invalidated_jwt: jwt_param)
    raise ActionController::BadRequest if invalidated_jwt.exists?

    JsonWebToken.decode(jwt_param)
  rescue StandardError
    render :unauthorized, status: :unauthorized
  end

  def invalidate_jwt
    JsonWebToken.create(invalidated_jwt: params[:jwt])
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def jwt_param
    params.require(:jwt)
  end
end
