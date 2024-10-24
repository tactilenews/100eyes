# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class TemplateFetcherService < ApplicationService
      def initialize(organization_id:)
        @organization = Organization.find(organization_id)
        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
      end

      attr_reader :base_uri, :organization

      def call
        url = URI.parse("#{base_uri}/v1/configs/templates")
        headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }

        request = Net::HTTP::Get.new(url, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        waba_templates = JSON.parse(response.body)['waba_templates']
        waba_templates.pluck('name').map(&:to_sym)
      end
    end
  end
end
