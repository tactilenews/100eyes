# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogOutbound
    class File < ApplicationJob
      queue_as :default

      def perform(message_id:, file_id:)
        @message = Message.find(message_id)
        organization = Organization.find(message.organization.id)

        @recipient = message.recipient
        @file_id = file_id

        url = URI.parse("#{ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')}/messages")
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

      attr_reader :recipient, :file_id, :message

      def payload
        {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: recipient.whats_app_phone_number.split('+').last,
          type: 'image',
          image: {
            id: file_id
          }
        }
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          external_id = JSON.parse(response.body)['messages'].first['id']
          message.update!(external_id: external_id)
        when Net::HTTPClientError, Net::HTTPServerError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
