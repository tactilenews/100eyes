# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class CreateApiKey < ApplicationJob
    def perform(channel_id:)
      @base_uri = Setting.three_sixty_dialog_partner_rest_api_endpoint

      token = Setting.find_by(var: 'three_sixty_dialog_partner_token')
      fetch_token unless token&.value && token.updated_at > 24.hours.ago
      partner_id = Setting.three_sixty_dialog_partner_id
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
      handle_response(response)
    end

    private

    attr_reader :base_uri

    def fetch_token
      url = URI.parse("#{base_uri}/token")
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
      setting = Setting.find_or_initialize_by(var: :three_sixty_dialog_partner_token)
      setting.value = token
      setting.save
    end

    def handle_response(response)
      case response.code.to_i
      when 201
        api_key = JSON.parse(response.body)['api_key']
        setting = Setting.find_or_initialize_by(var: :three_sixty_dialog_client_api_key)
        setting.value = api_key
        setting.save
        WhatsAppAdapter::SetWebhookUrl.perform_later
      when 400..599
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
