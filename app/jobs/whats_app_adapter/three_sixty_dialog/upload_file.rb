# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class UploadFile < ApplicationJob
      # rubocop:disable Metrics/AbcSize
      def perform(message_id:)
        @message_id = message_id
        message = Message.find_by(id: message_id)
        return unless message

        request = message.request
        organization = Organization.find_by(id: request.organization.id)
        return unless organization && organization.three_sixty_dialog_client_api_key.blank?

        request.files.each do |file|
          base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
          url = URI.parse("#{base_uri}/media")
          headers = {
            'D360-API-KEY': organization.three_sixty_dialog_client_api_key,
            'Content-Type': file.blob.content_type
          }
          request = Net::HTTP::Post.new(url.to_s, headers)
          request.body = File.read(ActiveStorage::Blob.service.path_for(file.blob.key))
          response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
            http.request(request)
          end
          handle_response(response)
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :message_id

      def handle_response(response)
        case response.code.to_i
        when 201
          file_id = JSON.parse(response.body)['media'].first['id']
          WhatsAppAdapter::ThreeSixtyDialogOutbound::File.perform_later(message_id: message_id, file_id: file_id)
        when 400..599
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
