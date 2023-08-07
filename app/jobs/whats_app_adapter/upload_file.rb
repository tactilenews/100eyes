# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class UploadFile < ApplicationJob
    def perform(message_id:)
      return if Setting.three_sixty_dialog_client_api_key.blank?

      @message_id = message_id
      message = Message.find(message_id)
      request = message.request

      request.files.each do |file|
        base_uri = Setting.three_sixty_dialog_whats_app_rest_api_endpoint
        url = URI.parse("#{base_uri}/media")
        headers = {
          'D360-API-KEY': Setting.three_sixty_dialog_client_api_key,
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

    private

    attr_reader :message_id

    def handle_response(response)
      case response.code.to_i
      when 201
        file_id = JSON.parse(response.body)['media'].first['id']
        WhatsAppAdapter::Outbound::ThreeSixtyDialogFile.perform_later(message_id: message_id, file_id: file_id)
      when 400..599
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
