# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogOutbound
    class File < ApplicationJob
      queue_as :default

      retry_on Net::HTTPServerError, wait: ->(executions) { executions * 3 } do |job, exception|
        if job.executions == 5
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: exception.code, message: exception.message)
          context = { message_id: job.arguments.first[:message_id] }
          ErrorNotifier.report(exception, context: context)
        end
      end

      def perform(message_id:)
        @message = Message.find(message_id)
        @recipient = message.recipient

        send_files
        send_text_separately unless caption_it?
      end

      private

      attr_reader :recipient, :message

      def send_files
        url = URI.parse("#{ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')}/messages")
        headers = { 'D360-API-KEY' => message.organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
        request = Net::HTTP::Post.new(url, headers)

        message.request.whats_app_external_file_ids.each do |file_id|
          body = payload(file_id)
          body[:image][:caption] = message.text if caption_it?

          request.body = body.to_json
          response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
            http.request(request)
          end
          handle_response(response)
        end
      end

      def send_text_separately
        WhatsAppAdapter::ThreeSixtyDialogOutbound::Text.perform_later(
          organization_id: message.organization_id,
          payload: text_payload,
          message_id: message.id
        )
      end

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
          if caption_it?
            external_id = JSON.parse(response.body)['messages'].first['id']
            message.update!(external_id: external_id)
          end
        when Net::HTTPClientError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          context = { message_id: message.id }
          ErrorNotifier.report(exception, context: context)
        end
      end

      def caption_it?
        message.request.whats_app_external_file_ids.length.eql?(1) && message.text.length < 1024
      end
    end
  end
end
