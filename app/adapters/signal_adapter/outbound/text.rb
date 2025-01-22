# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      attr_reader :recipient, :text, :organization

      def perform(organization_id:, contributor_id:, text:, message: nil)
        @organization = Organization.find(organization_id)
        @recipient = @organization.contributors.find(contributor_id)

        @text = text
        uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v2/send")
        request = Net::HTTP::Post.new(uri, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        SignalAdapter::Api.perform_request(organization, request, recipient) do |response|
          datetime = Time.zone.at(JSON.parse(response.body)['timestamp'].to_i / 1000).to_datetime

          message&.update(sent_at: datetime)
        end
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
      end

      def data
        {
          number: organization.signal_server_phone_number,
          recipients: [recipient.signal_attr],
          message: text
        }
      end
    end
  end
end
