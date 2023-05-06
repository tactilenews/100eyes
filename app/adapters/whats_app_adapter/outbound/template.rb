# frozen_string_literal: true

module WhatsAppAdapter
  class Outbound
    class Template < ApplicationJob
      queue_as :default

      def perform(payload:)
        url = URI.parse('https://hub.360dialog.com/v1/messages')
        request = Net::HTTP::Post.new(url.to_s, {
                                        Accept: 'application/json',
                                        'Content-Type': 'application/json',
                                        Authorization: "Bearer #{ENV.fetch('360_DIALOG_ACCESS_TOKEN', '')}"
                                      })

        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        response.value # may raise exception
      end
    end
  end
end
