# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class UploadFileService < ApplicationService
      def initialize(request_id:)
        @broadcasted_request = Request.find(request_id)
        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
      end

      def call
        url = URI.parse("#{base_uri}/media")
        headers = {
          'D360-API-KEY' => broadcasted_request.organization.three_sixty_dialog_client_api_key
        }

        broadcasted_request.files.each do |file|
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
        broadcasted_request.save!
      end

      private

      attr_reader :broadcasted_request, :base_uri

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          external_file_id = JSON.parse(response.body)['id']
          broadcasted_request.whats_app_external_file_ids << external_file_id
        when Net::HTTPClientError, Net::HTTPServerError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
