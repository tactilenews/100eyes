# frozen_string_literal: true

module SignalAdapter
  class RegisterPhoneNumberService
    attr_reader :register_data, :uri

    def initialize(organization_id:, register_data:)
      @organization = Organization.find(organization_id)
      @uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/register/#{@organization.signal_server_phone_number}")
      @register_data = register_data
    end

    def call
      request = Net::HTTP::Post.new(uri, {
                                      Accept: 'application/json',
                                      'Content-Type': 'application/json'
                                    })
      request.body = register_data.to_json
      Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
    end
  end
end
