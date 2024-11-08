# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogOutbound
    class File < ApplicationJob
      queue_as :default

      # rubocop:disable Metrics/AbcSize
      def perform(message_id:)
        @message = Message.find(message_id)
        organization = Organization.find(message.organization.id)

        @recipient = message.recipient

        unless caption_it?
          WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(organization_id: message.organization_id, payload: text_payload,
                                                                        message_id: message.id)
        end

        message.request.external_file_ids.each do |file_id|
          url = URI.parse("#{ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')}/messages")
          headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
          request = Net::HTTP::Post.new(url.to_s, headers)
          body = payload(file_id)
          body[:image][:caption] = message.text if caption_it?

          request.body = body.to_json
          response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
            http.request(request)
          end
          handle_response(response)
        end
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :recipient, :message

      def payload(file_id)
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

      def text_payload
        {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: recipient.whats_app_phone_number.split('+').last,
          type: 'text',
          text: {
            body: message.text
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

      def caption_it?
        message.request.external_file_ids.length.eql?(1) && message.text.length < 1024
      end
    end
  end
end
