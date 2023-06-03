# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class CreateApiKey < ApplicationJob
    def perform(channel_id:)
      token = Setting.find_by(var: 'three_sixty_dialog_partner_token')
      fetch_token unless token&.value && token.updated_at > 24.hours.ago
      base_uri = Setting.three_sixty_dialog[:partner][:rest_api_endpoint]
      partner_id = Setting.three_sixty_dialog[:partner][:id]
      url = URI.parse(
        "#{base_uri}/partners/#{partner_id}/channels/#{channel_id}/api_keys"
      )
      headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{Setting.three_sixty_dialog_partner_token}"
      }
      request = Net::HTTP::Post.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      api_key = JSON.parse(response.body)['api_key']
      Setting.three_sixty_dialog_api_key = api_key
    end

    private

    def fetch_token
      url = URI.parse("#{Setting.three_sixty_dialog_partner_rest_api_endpoint}/token")
      headers = {
        'Content-Type': 'application/json'
      }
      request = Net::HTTP::Post.new(url.to_s, headers)
      request.body = {
        username: Setting.three_sixty_dialog_partner_username,
        password: Setting.three_sixty_dialog_partner_password
      }.to_json
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      token = JSON.parse(response.body)['access_token']
      Setting.three_sixty_dialog_partner_token = token
    end
  end
end
