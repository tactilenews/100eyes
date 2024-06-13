# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class SetTrustModeJob < ApplicationJob
    def perform(signal_server_phone_number:)
      uri = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/configuration/#{signal_server_phone_number}/settings")
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
        error_message = JSON.parse(response.body)['error']
        MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id) if error_message.match?(/Unregistered user/)
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
end
