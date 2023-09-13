# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      attr_reader :message

      def perform(message:)
        @message = message
        url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v2/send")
        request = Net::HTTP::Post.new(url.to_s, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        response = Net::HTTP.start(url.host, url.port) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      def data
        base64_files = message.files.map do |file|
          Base64.encode64(::File.open(ActiveStorage::Blob.service.path_for(file.attachment.blob.key), 'rb').read)
        end
        {
          number: Setting.signal_server_phone_number,
          recipients: [message.recipient.signal_phone_number],
          message: message.text,
          base64_attachments: base64_files
        }
      end

      def handle_response(response)
        case response.code.to_i
        when 200
          # TODO: Do something on success. For example, mark the message as delivered?
          # Or should we use deliver receipts as the source of truth.
          Rails.logger.debug 'Great!'
        when 400..599
          error_message = JSON.parse(response.body)['error']
          exception = SignalAdapter::BadRequestError.new(error_code: response.code, message: error_message)
          context = {
            code: response.code,
            message: response.message,
            headers: response.to_hash,
            body: error_message
          }
          ErrorNotifier.report(exception, context: context)
        end
      end
    end
  end
end
