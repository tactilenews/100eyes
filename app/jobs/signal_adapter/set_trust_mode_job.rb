# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class SetTrustModeJob < ApplicationJob
    def perform(signal_server_phone_number:)
      uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/configuration/#{signal_server_phone_number}/settings")
      request = Net::HTTP::Post.new(uri, {
                                      Accept: 'application/json',
                                      'Content-Type': 'application/json'
                                    })
      request.body = { trust_mode: 'always' }.to_json
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
      case response
      when Net::HTTPSuccess
        Rails.logger.debug 'Updated config'
      else
        handle_error(JSON.parse(response.body)['error'])
      end
    end

    private

    def handle_error(error_message)
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
