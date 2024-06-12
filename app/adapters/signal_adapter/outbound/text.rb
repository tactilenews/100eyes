# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      attr_reader :recipient, :text, :organization

      def perform(contributor_id:, text:, organization_id: nil)
        @recipient = Contributor.find_by(id: contributor_id)
        @organization = Organization.find_by(id: organization_id)
        return unless @recipient

        @text = text
        uri = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v2/send")
        request = Net::HTTP::Post.new(uri, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        SignalAdapter::Api.perform_request(request, recipient) do
          # TODO: Do something on success. For example, mark the message as delivered?
          # Or should we use deliver receipts as the source of truth.
          Rails.logger.debug 'Great!'
        end
      end

      def data
        {
          number: organization&.signal_server_phone_number || Setting.signal_server_phone_number,
          recipients: [recipient.signal_phone_number],
          message: text
        }
      end
    end
  end
end
