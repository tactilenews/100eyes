# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      attr_reader :recipient, :text, :organization, :quote_message

      def perform(contributor_id:, text:, message: nil)
        @recipient = Contributor.find(contributor_id)
        @organization = recipient.organization
        @quote_message = Message.find_by(external_id: message.reply_to_external_id) if message&.reply_to_external_id

        @text = text
        uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v2/send")
        request = Net::HTTP::Post.new(uri, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        SignalAdapter::Api.perform_request(organization, request, recipient) do |response|
          datetime = Time.zone.at(JSON.parse(response.body)['timestamp'].to_i / 1000).to_datetime

          message&.update(sent_at: datetime, external_id: JSON.parse(response.body)['timestamp'])
        end
      end

      def data
        base_data = {
          number: organization.signal_server_phone_number,
          recipients: [recipient.signal_attr],
          message: text
        }

        if quote_message.present?
          base_data.merge!({
                             quote_author: quote_message.sender.signal_phone_number || quote_message.sender.signal_uuid,
                             quote_timestamp: quote_message.external_id.to_i
                           })
        end
        base_data
      end
    end
  end
end
