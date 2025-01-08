# frozen_string_literal: true

module Organizations
  class SignalController < ApplicationController
    def captcha_form; end

    def register
      response = SignalAdapter::RegisterPhoneNumberService.new(organization_id: @organization.id, register_data: register_data).call
      case response
      when Net::HTTPSuccess
        redirect_to organization_signal_verify_path
      else
        handle_error_response(response)
        render :captcha_form, status: :unprocessable_entity
      end
    end

    def verify_form; end

    def verify
      token = params[:organization][:signal][:token]
      response = SignalAdapter::VerifyPhoneNumberService.new(organization_id: @organization.id, token: token).call
      case response
      when Net::HTTPSuccess
        SignalAdapter::SetTrustModeJob.perform_later(signal_server_phone_number: @organization.signal_server_phone_number)
        SignalAdapter::SetUsernameJob.perform_later(organization_id: @organization.id)
        SignalAdapter::SetProfileInfoJob.perform_later(organization_id: @organization.id)
        redirect_to organization_signal_setup_successful_path
      else
        handle_error_response(response)
        render :verify_form, status: :unprocessable_entity
      end
    end

    def success; end

    private

    def update_params
      params.require(:organization).permit(:signal_server_phone_number)
    end

    def signal_server_phone_number
      @organization.signal_server_phone_number
    end

    def register_data
      {
        captcha: params[:organization][:signal][:captcha],
        use_voice: ActiveModel::Type::Boolean.new.cast(params[:organization][:signal][:use_voice])
      }
    end

    def handle_error_response(response)
      error_message = JSON.parse(response.body)['error']
      exception = SignalAdapter::BadRequestError.new(error_code: response.code, message: error_message)
      context = {
        code: response.code,
        message: response.message,
        headers: response.to_hash,
        body: error_message
      }
      ErrorNotifier.report(exception, context: context)
      flash.now[:error] = error_message
    end
  end
end
