# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class CreateApiKey
    def perform(channel_id:)
      url = URI.parse(" https://hub.360dialog.io/api/v2/partners/#{ENV.fetch('360_DIALOG_PARTNER_ID', '')}/channels/#{channel_id}/api_keys")
      headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{ENV.fetch('360_DIALOG_ACCESS_TOKEN', '')}"
      }
      request = Net::HTTP::Post.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port) do |http|
        http.request(request)
      end
      api_key = response.body['api_key']
      Setting.three_sixty_dialog_api_key = api_key
    end
  end
end
