# frozen_string_literal: true

module Onboarding
  class TelegramController < ApplicationController
    skip_before_action :require_login
    before_action :verify_onboarding_jwt, except: %i[update]
    before_action :verify_telegram_authentication_and_integrity, only: :create

    layout 'onboarding'

    def info
      @jwt = jwt_param
    end

    def create
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
      cookies.encrypted[:telegram_id] = { value: @contributor.telegram_id, expires: 30.minutes }
    end

    def update
      @contributor = Contributor.find_by(telegram_id: cookies.encrypted[:telegram_id])

      if @contributor&.update(first_name: contributor_params[:first_name], last_name: contributor_params[:last_name])
        redirect_to_success
      else
        render 'onboarding/unauthorized', status: :unauthorized
      end
    end

    private

    def verify_onboarding_jwt
      invalidated_jwt = JsonWebToken.where(invalidated_jwt: jwt_param)
      raise ActionController::BadRequest if invalidated_jwt.exists?

      decoded_token = JsonWebToken.decode(jwt_param)

      raise ActionController::BadRequest if decoded_token.first['data']['action'] != 'onboarding'
    rescue StandardError
      render 'onboarding/unauthorized', status: :unauthorized
    end

    def invalidate_jwt
      JsonWebToken.create(invalidated_jwt: params[:jwt])
    end

    def redirect_to_success
      redirect_to onboarding_success_path
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

    def verify_telegram_authentication_and_integrity
      auth_data = telegram_auth_params.slice(:id, :auth_date, :first_name, :last_name, :username, :photo_url)
      check_string = auth_data.to_unsafe_h.map { |k, v| "#{k}=#{v}" }.sort.join("\n")

      secret_key = OpenSSL::Digest.new('SHA256').digest(Setting.telegram_bot_api_key)
      valid_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, check_string)
      valid_time_window = Time.zone.now.to_i - telegram_auth_params[:auth_date].to_i < 24 * 60 * 60

      raise ActionController::BadRequest unless valid_hash.casecmp(telegram_auth_params[:hash]).zero? && valid_time_window
    end
  end
end
