# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class SetProfileInfoJob < ApplicationJob
      def perform(organization_id:)
        organization = Organization.find(organization_id)
        return if organization.three_sixty_dialog_client_api_key.blank?

        base_uri = URI.parse(ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693'))
        url = URI.parse("#{base_uri}/whatsapp_business_profile")
        headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key }
        params = {
          'messaging_product' => 'whatsapp',
          'about' => organization.messengers_about_text,
          'description' => organization.messengers_description_text
        }
        request = Net::HTTP::Post::Multipart.new(url, params, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      private

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          Rails.logger.debug 'Successfully set profile info job!'
        when Net::HTTPClientError, Net::HTTPServerError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
