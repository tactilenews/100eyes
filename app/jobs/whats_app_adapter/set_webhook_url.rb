# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class SetWebhookUrl < ApplicationJob
    def perform(organization_id:)
      organization = Organization.find_by(id: organization_id)
      return unless organization && organization.three_sixty_dialog_client_api_key.present?

      base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
      url = URI.parse("#{base_uri}/configs/webhook")
      headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
      request = Net::HTTP::Post.new(url.to_s, headers)

      request.body = { url: "https://#{ENV.fetch('APPLICATION_HOSTNAME',
                                                 'localhost:3000')}/#{organization_id}/whats_app/three-sixty-dialog-webhook" }.to_json
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      handle_response(response)
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
