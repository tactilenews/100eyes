# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class CreateApiKey < ApplicationJob
    def perform(organization_id:, channel_id:)
      @organization = Organization.find_by(id: organization_id)
      return unless organization && ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil).present?

      @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')

      @token = fetch_token
      partner_id = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)

      url = URI.parse(
        "#{base_uri}/partners/#{partner_id}/channels/#{channel_id}/api_keys"
      )
      headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{token}"
      }
      request = Net::HTTP::Post.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      handle_response(response)
    end

    private

    attr_reader :base_uri, :organization, :token

    def fetch_token
      url = URI.parse("#{base_uri}/token")
      headers = {
        'Content-Type': 'application/json'
      }
      request = Net::HTTP::Post.new(url.to_s, headers)
      request.body = {
        username: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_USERNAME', nil),
        password: ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_PASSWORD', nil)
      }.to_json
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      JSON.parse(response.body)['access_token']
    end

    def handle_response(response)
      case response.code.to_i
      when 201
        api_key = JSON.parse(response.body)['api_key']
        Rails.logger.debug api_key
        organization.update!(three_sixty_dialog_client_api_key: api_key)
        WhatsAppAdapter::SetWebhookUrl.perform_later(organization_id: organization.id)
        WhatsAppAdapter::CreateTemplates.perform_later(organization_id: organization.id, token: token)

      when 400..599
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
