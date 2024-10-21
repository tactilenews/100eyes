# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class TemplateCreatorService
      def initialize(organization_id:, payload:)
        @organization = Organization.find(organization_id)
        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        @payload = payload
      end

      attr_reader :base_uri, :organization, :payload

      def call
        url = URI.parse("#{base_uri}/v1/configs/templates")
        headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }

        request = Net::HTTP::Post.new(url.to_s, headers)
        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      private

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          WhatsAppTemplateCreated.with(organization_id: organization.id).deliver_later(organization.users + User.admin.all)
        when Net::HTTPClientError, Net::HTTPServerError
          return if response.body.match?(/you have provided is already in use. Please choose a different name for your template./)

          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
