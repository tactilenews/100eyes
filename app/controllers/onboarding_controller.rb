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
    if Contributor.email_taken?(contributor_params[:email]) || Contributor.find_by(telegram_id: contributor_params[:telegram_id])
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

  def telegram_auth
    authenticate_telegram_params
    telegram_id = telegram_auth_params[:id]
    first_name = telegram_auth_params[:first_name]
    last_name = telegram_auth_params[:last_name]
    redirect_to onboarding_telegram_path(jwt: jwt_param, id: telegram_id, first_name: first_name, last_name: last_name)
  end

  def telegram
    @first_name = telegram_auth_params[:first_name]
    @last_name = telegram_auth_params[:last_name]
    @telegram_id = telegram_auth_params[:id]
    @contributor = Contributor.new
    @jwt = jwt_param
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
    params.require(:contributor).permit(:first_name, :last_name, :email, :telegram_id)
  end

  def jwt_param
    params.require(:jwt)
  end

  def telegram_auth_params
    params.permit(:id, :first_name, :last_name, :auth_date, :hash, :username, :photo_url)
  end

  def authenticate_telegram_params
    auth_data = telegram_auth_params.slice(:id, :auth_date, :first_name, :last_name, :username, :photo_url)
    check_string = auth_data.to_unsafe_h.map { |k, v| "#{k}=#{v}" }.sort.join("\n")

    secret_key = OpenSSL::Digest.new('SHA256').digest(Setting.telegram_bot_api_key)
    valid_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, check_string)
    valid_time_window = Time.zone.now.to_i - telegram_auth_params[:auth_date].to_i < 24 * 60 * 60

    raise ActionController::BadRequest unless valid_hash.casecmp(telegram_auth_params[:hash]).zero? && valid_time_window
  end
end
