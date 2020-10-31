# frozen_string_literal: true

class OnboardingController < ApplicationController
  skip_before_action :authenticate, except: :create_invite_url
  before_action :verify_jwt, except: %i[create_invite_url success]

  layout 'onboarding'

  def index
    @jwt = jwt_param
    @contributor = Contributor.new
  end

  def create
    # Ensure information on registered contributors is never
    # disclosed during onboarding
    if Contributor.email_taken?(contributor_params[:email])
      invalidate_jwt
      return redirect_to_success
    end

    @contributor = Contributor.new(contributor_params)

    if @contributor.save
      invalidate_jwt
      return redirect_to_success
    end

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

  def contributor_params
    params.require(:contributor).permit(:first_name, :last_name, :email)
  end

  def jwt_param
    params.require(:jwt)
  end
end
