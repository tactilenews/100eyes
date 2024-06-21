# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      attr_reader :message, :organization

      def perform(message:)
        @message = message
        @organization = @message.organization
        uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v2/send")
        request = Net::HTTP::Post.new(uri, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        SignalAdapter::Api.perform_request(organization, request, message.recipient) do
          # TODO: Do something on success. For example, mark the message as delivered?
          # Or should we use deliver receipts as the source of truth.
          Rails.logger.debug 'Great!'
        end
      end

      def data
        base64_files = message.files.map do |file|
          Base64.encode64(::File.open(ActiveStorage::Blob.service.path_for(file.attachment.blob.key), 'rb').read)
        end
        {
          number: organization.signal_server_phone_number,
          recipients: [message.recipient.signal_attr],
          message: message.text,
          base64_attachments: base64_files
        }
      end
    end
  end
end
