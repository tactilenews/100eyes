# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class ThreeSixtyDialogText < ApplicationJob
      queue_as :default

      def perform(organization_id:, payload:)
        organization = Organization.find(organization_id)

        url = URI.parse("#{ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')}/messages")
        headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
        request = Net::HTTP::Post.new(url.to_s, headers)

        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end

      private

      def handle_response(response)
        case response.code.to_i
        when 201
          Rails.logger.debug 'Great!'
        when 400..599
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
