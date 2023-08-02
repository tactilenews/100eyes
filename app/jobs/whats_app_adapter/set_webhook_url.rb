# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class SetWebhookUrl < ApplicationJob
    def perform
      return unless Setting.three_sixty_dialog_api_key

      base_uri = Setting.three_sixty_dialog_whats_app_rest_api_endpoint
      url = URI.parse("#{base_uri}/configs/webhook")
      headers = { 'D360-API-KEY' => Setting.three_sixty_dialog_api_key, 'Content-Type' => 'application/json' }
      request = Net::HTTP::Post.new(url.to_s, headers)

      request.body = { url: "https://#{Setting.application_host}/whats_app/three-sixty-dialog-webhook" }.to_json
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      handle_response(response)
    end

    private

    def handle_response(response)
      case response.code.to_i
      when 200
        Rails.logger.debug 'Great!'
      when 400..599
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
