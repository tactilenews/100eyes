# frozen_string_literal: true

require 'openssl'

class OnboardingController < ApplicationController
  skip_before_action :require_login, except: :create_invite_url
  before_action :verify_onboarding_jwt, except: %i[create_invite_url success telegram_update_info]
  before_action :verify_telegram_authentication_and_integrity, only: :telegram
  before_action :verify_update_jwt, only: :telegram_update_info

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
    payload = { invite_code: SecureRandom.base64(16), action: 'onboarding' }
    jwt = create_jwt(payload)
    render json: { url: onboarding_url(jwt: jwt) }
  end

  def telegram_explained
    @jwt = jwt_param
  end

  def telegram
    @telegram_id = telegram_auth_params[:id]
    @first_name = telegram_auth_params[:first_name]
    @last_name = telegram_auth_params[:last_name]
    if Contributor.exists?(telegram_id: @telegram_id)
      invalidate_jwt
      return redirect_to_success
    end

    @contributor = Contributor.new(
      telegram_id: @telegram_id,
      first_name: @first_name,
      last_name: @last_name,
      username: telegram_auth_params[:username],
      avatar_url: telegram_auth_params[:avatar_url]
    )
    return unless @contributor.save

    invalidate_jwt
    payload = { telegram_id: @contributor.telegram_id, action: 'update' }
    @jwt = create_jwt(payload, expires_in: 30.minutes.from_now.to_i)
  end

  def telegram_update_info
    decoded_token = JsonWebToken.decode(jwt_param)
    @contributor = Contributor.where(telegram_id: decoded_token.first['data']['telegram_id'])
    @contributor.update(first_name: contributor_params[:first_name], last_name: contributor_params[:last_name])
    redirect_to_success
  end

  private

  def redirect_to_success
    redirect_to onboarding_success_path
  end

  def verify_onboarding_jwt
    invalidated_jwt = JsonWebToken.where(invalidated_jwt: jwt_param)
    raise ActionController::BadRequest if invalidated_jwt.exists?

    decoded_token = JsonWebToken.decode(jwt_param)

    raise ActionController::BadRequest if decoded_token.first['data']['action'] != 'onboarding'
  rescue StandardError
    render :unauthorized, status: :unauthorized
  end

  def verify_update_jwt
    decoded_token = JsonWebToken.decode(jwt_param)

    if decoded_token.first['data']['action'] != 'update' || decoded_token.first['data']['telegram_id'].blank?
      raise ActionController::BadRequest
    end
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
    params.permit(:id, :first_name, :last_name, :auth_date, :hash, :username, :photo_url)
  end

  def create_jwt(payload, expires_in: 48.hours.from_now.to_i)
    JsonWebToken.encode(payload, expires_in: expires_in)
  end

  def verify_telegram_authentication_and_integrity
    auth_data = telegram_auth_params.slice(:id, :auth_date, :first_name, :last_name, :username, :photo_url)
    check_string = auth_data.to_unsafe_h.map { |k, v| "#{k}=#{v}" }.sort.join("\n")

    secret_key = OpenSSL::Digest.new('SHA256').digest(Setting.telegram_bot_api_key)
    valid_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, check_string)
    valid_time_window = Time.zone.now.to_i - telegram_auth_params[:auth_date].to_i < 24 * 60 * 60

    raise ActionController::BadRequest unless valid_hash.casecmp(telegram_auth_params[:hash]).zero? && valid_time_window
  end
end
