# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class ThreeSixtyDialogFile < ApplicationJob
      queue_as :default

      def perform(message_id:, file_id:)
        message = Message.find(message_id)
        @recipient = message.recipient
        @file_id = file_id

        url = URI.parse("#{Setting.three_sixty_dialog_whats_app_rest_api_endpoint}/messages")
        headers = { 'D360-API-KEY' => Setting.three_sixty_dialog_api_key, 'Content-Type' => 'application/json' }
        request = Net::HTTP::Post.new(url.to_s, headers)
        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      private

      attr_reader :recipient, :file_id

      def payload
        {
          recipient_type: 'individual',
          to: recipient.whats_app_phone_number.split('+').last,
          type: 'image',
          image: {
            id: file_id
          }
        }
      end

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
end
