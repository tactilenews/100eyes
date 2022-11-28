# frozen_string_literal: true

module SignalAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      attr_reader :recipient, :text

      def perform(recipient:, text:)
        @recipient = recipient
        @text = text
        url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v2/send")
        request = Net::HTTP::Post.new(url.to_s, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json'
                                      })
        request.body = data.to_json
        response = Net::HTTP.start(url.host, url.port) do |http|
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
        {
          number: Setting.signal_server_phone_number,
          recipients: [recipient.signal_phone_number],
          message: text
        }
      end
    end
  end
end
