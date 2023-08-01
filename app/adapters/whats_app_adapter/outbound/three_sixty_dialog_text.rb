# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class ThreeSixtyDialogText < ApplicationJob
      queue_as :default

      def perform(payload:)
        url = URI.parse("#{Setting.three_sixty_dialog_whats_app_rest_api_endpoint}/messages")
        headers = { 'D360-API-KEY' => Setting.three_sixty_dialog_api_key, 'Content-Type' => 'application/json' }
        request = Net::HTTP::Post.new(url.to_s, headers)

        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        response.value # may raise exception
      end
    end
  end
end
