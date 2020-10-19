# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate
  before_action :verify_token
  skip_before_action :verify_token, only: %i[create_invite_url]

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
    return redirect_to_success if @user.save

    render :index
  end

  def success; end

  def create_invite_url
    payload = SecureRandom.base64(16)
    jwt = JsonWebToken.encode(payload)
    render json: { url: URI::HTTPS.build(path: '/onboarding', query: "jwt=#{jwt}") }
  end

  private

  def redirect_to_success
    redirect_to onboarding_success_path(jwt: jwt_param)
  end

  def verify_token
    invalidated_jti = JsonWebToken.find_by(invalidated_jti: jwt_param)
    raise ActionController::BadRequest if invalidated_jti.present?

    JsonWebToken.decode(jwt_param)

    # rescue JWT::DecodeError => error
    #   render json: { errors: error.message }, status: :unauthorized
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :email)
  end

  def jwt_param
    params.require(:jwt)
  end
end
