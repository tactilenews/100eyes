# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class FileFetcher
      attr_reader :organization, :base_uri, :headers, :file_id

      def initialize(organization_id:, file_id:)
        @organization = Organization.find(organization_id)
        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        @headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
        @file_id = file_id
      end

      def fetch_streamable_file
        response = fetch_file_url
        media_url = URI.parse(JSON.parse(response.body)['url'])
        base_url = URI.parse(base_uri)
        url = URI::HTTPS.build(host: base_url.hostname, path: base_url.path + media_url.path)
        request = Net::HTTP::Get.new(url.to_s, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        response.body
      end

      private

      def fetch_file_url
        url = URI.parse("#{base_uri}/#{file_id}")
        request = Net::HTTP::Get.new(url.to_s, headers)
        Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
      end
    end
  end
end
