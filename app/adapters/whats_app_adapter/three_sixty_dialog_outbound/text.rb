# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogOutbound
    class Text < ApplicationJob
      queue_as :default

      retry_on Net::HTTPServerError, wait: ->(executions) { executions * 3 } do |job, exception|
        if job.executions == 5
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: exception.code, message: exception.message)
          context = { message_id: job.arguments.first[:message_id], recipient: job.payload[:to] }
          ErrorNotifier.report(exception, context: context)
        end
      end

      def perform(organization_id:, payload:, message_id: nil)
        @message = Message.find(message_id) if message_id
        @payload = payload
        organization = Organization.find(organization_id)

        url = URI.parse("#{ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')}/messages")
        headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }
        request = Net::HTTP::Post.new(url, headers)

        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      attr_reader :message, :payload

      private

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          external_id = JSON.parse(response.body)['messages'].first['id']
          message&.update!(external_id: external_id)
        when Net::HTTPClientError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          context = { message_id: message&.id, recipient: payload[:to] }
          ErrorNotifier.report(exception, context: context)
        end
      end
    end
  end
end
