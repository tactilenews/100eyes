# frozen_string_literal: true

module Organizations
  class SignalController < ApplicationController
    def captcha_form; end

    def register
      uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/register/#{signal_server_phone_number}")
      request = Net::HTTP::Post.new(uri, {
                                      Accept: 'application/json',
                                      'Content-Type': 'application/json'
                                    })
      request.body = register_data.to_json
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
      case response
      when Net::HTTPSuccess
        redirect_to organization_signal_verify_path
      else
        handle_error_response(response)
      end
    end

    def verify_form; end

    def verify
      token = params[:organization][:signal][:token]
      uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/register/#{signal_server_phone_number}/verify/#{token}")
      request = Net::HTTP::Post.new(uri, {
                                      Accept: 'application/json',
                                      'Content-Type': 'application/json'
                                    })
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
      case response
      when Net::HTTPSuccess
        SignalAdapter::SetTrustModeJob.perform_later(signal_server_phone_number: signal_server_phone_number)
      else
        handle_error_response(response)
      end
    end

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
        use_voice: false
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
    end
  end
end
