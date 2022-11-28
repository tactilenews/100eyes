# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      attr_reader :message

      def perform(message:)
        @message = message
        request = Net::HTTP::Post.new(SignalAdapter::Outbound::SEND_URL.to_s, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        response = Net::HTTP.start(SignalAdapter::Outbound::SEND_URL.host, SignalAdapter::Outbound::SEND_URL.port) do |http|
          http.request(request)
        end
        response.value # may raise exception
      rescue Net::HTTPClientException => e
        ErrorNotifier.report(e, context: {
                               code: e.response.code,
                               message: e.response.message,
                               headers: e.response.to_hash,
                               body: e.response.body
                             })
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
    end
  end
end
