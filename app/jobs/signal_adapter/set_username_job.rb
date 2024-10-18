# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class SetUsernameJob < ApplicationJob
    def perform(organization_id:)
      organization = Organization.find(organization_id)
      uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/accounts/#{organization.signal_server_phone_number}/username")
      request = Net::HTTP::Post.new(uri, {
                                      Accept: 'application/json',
                                      'Content-Type': 'application/json'
                                    })
      request.body = { username: organization.project_name.gsub(/[^\w\s]/, '').gsub(/\s+/, '').camelize }.to_json
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
      case response
      when Net::HTTPSuccess
        organization.update!(signal_complete_onboarding_link: JSON.parse(response.body)['username_link'])
      else
        handle_error(response)
      end
    end

    private

    def handle_error(response)
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
