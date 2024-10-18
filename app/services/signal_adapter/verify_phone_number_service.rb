# frozen_string_literal: true

module SignalAdapter
  class VerifyPhoneNumberService
    attr_reader :token, :uri, :organization

    def initialize(organization_id:, token:)
      @organization = Organization.find(organization_id)
      @uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/register/#{organization.signal_server_phone_number}/verify/#{token}")
      @token = token
    end

    def call
      request = Net::HTTP::Post.new(uri, {
                                      Accept: 'application/json',
                                      'Content-Type': 'application/json'
                                    })
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
    end
  end
end
