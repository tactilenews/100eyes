# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class FileFetcherService
      class FetchError < StandardError; end

      attr_reader :organization, :base_uri, :headers, :file_id

      def initialize(organization_id:, file_id:)
        @organization = Organization.find(organization_id)
        @base_uri = URI.parse(ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'))
        @headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
        @file_id = file_id
      end

      def call
        url = URI::HTTPS.build(host: base_uri.hostname, path: base_uri.path + "/#{file_id}")
        request = Net::HTTP::Get.new(url.to_s, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          fetch_streamable_file(URI.parse(JSON.parse(response.body)['url']))
        when Net::HTTPClientError, Net::HTTPServerError
          handle_error(response)
        end
      end

      private

      def fetch_streamable_file(media_url)
        url = URI::HTTPS.build(host: base_uri.hostname, path: base_uri.path + media_url.path, query: media_url.query)
        request = Net::HTTP::Get.new(url.to_s, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end

        case response
        when Net::HTTPSuccess
          response.body
        when Net::HTTPClientError, Net::HTTPServerError
          handle_error(response)
        end
      end

      def handle_error(response)
        exception = WhatsAppAdapter::ThreeSixtyDialog::FileFetcherService::FetchError.new(
          "Fetching of #{file_id} failed with message: #{response.message}"
        )
        ErrorNotifier.report(exception)
      end
    end
  end
end
