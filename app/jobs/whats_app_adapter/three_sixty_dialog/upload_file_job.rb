# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class UploadFileJob < ApplicationJob
      def perform(message_id:)
        @message_id = message_id
        message = Message.find_by(id: message_id)

        request = message.request
        organization = request.organization

        base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        url = URI.parse("#{base_uri}/media")
        headers = {
          'D360-API-KEY' => organization.three_sixty_dialog_client_api_key
        }

        request.files.each do |file|
          params = {
            'messaging_product' => 'whatsapp',
            'file' => UploadIO.new(ActiveStorage::Blob.service.path_for(file.blob.key), file.blob.content_type)
          }
          request = Net::HTTP::Post::Multipart.new(url, params, headers)
          response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
            http.request(request)
          end

          handle_response(response)
        end
      end

      private

      attr_reader :message_id

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          file_id = JSON.parse(response.body)['id']
          WhatsAppAdapter::ThreeSixtyDialogOutbound::File.perform_later(message_id: message_id, file_id: file_id)
        when Net::HTTPClientError, Net::HTTPServerError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
