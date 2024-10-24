# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class TokenFetcherService < ApplicationService
      def self.call
        base_uri = URI.parse(
          ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        )
        url = URI::HTTPS.build(host: base_uri.hostname, path: "#{base_uri.path}/token")
        headers = { 'Content-Type': 'application/json' }
        request = Net::HTTP::Post.new(url, headers)
        request.body = {
          username: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_USERNAME', nil),
          password: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_PASSWORD', nil)
        }.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        JSON.parse(response.body)['access_token']
      end
    end
  end
end
