# frozen_string_literal: true

require 'openssl'

class OnboardingController < ApplicationController
  skip_before_action :authenticate, except: :create_invite_url
  before_action :verify_jwt, except: %i[create_invite_url success]
  before_action :telegram_auth_params, only: :telegram_auth

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

  # rubocop:disable Metrics/AbcSize
  def telegram_auth
    check_hash = telegram_auth_params[:hash]
    auth_data = telegram_auth_params.slice(:auth_date, :first_name, :id, :last_name)
    check_string = auth_data.to_unsafe_h.map { |k, v| "#{k}=#{v}" }.sort.join("\n")

    secret_key = OpenSSL::Digest::SHA256.new.digest(ENV['TELEGRAM_BOT_API_KEY'])
    hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, check_string)

    raise ActionController::BadRequest if hash.casecmp(check_hash) != 0
    raise ActionController::BadRequest if Time.now.to_i - telegram_auth_params[:auth_date].to_i > 24 * 60 * 60

    @user = User.find_or_create_by(
      telegram_id: telegram_auth_params[:id],
      first_name: telegram_auth_params[:first_name],
      last_name: telegram_auth_params[:last_name]
    )
    if @user.save
      render json: { message: 'Success' }, status: :ok
    else
      render json: { status: :error }
    end
  end
  # rubocop:enable Metrics/AbcSize

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

  def telegram_auth_params
    params.permit(:id, :first_name, :last_name, :auth_date, :hash)
  end
end
