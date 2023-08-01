# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class CreateTemplate < ApplicationJob
    def perform(template_name:, template_text:)
      @base_uri = Setting.three_sixty_dialog_partner_rest_api_endpoint
      @partner_id = Setting.three_sixty_dialog_partner_id
      @template_name = template_name
      @template_text = template_text

      token = Setting.find_by(var: 'three_sixty_dialog_partner_token')
      fetch_token unless token&.value && token.updated_at > 24.hours.ago

      waba_account_id = Setting.three_sixty_dialog_client_waba_account_id
      waba_account_id = fetch_waba_account_id if waba_account_id.blank?

      url = URI.parse(
        "#{base_uri}/partners/#{partner_id}/waba_accounts/#{waba_account_id}/waba_templates"
      )
      headers = set_headers

      request = Net::HTTP::Post.new(url.to_s, headers)
      request.body = template_payload.to_json
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      handle_response(response)
    end

    attr_reader :base_uri, :partner_id, :template_name, :template_text

    private

    def set_headers
      {
        'D360-API-KEY': Setting.three_sixty_dialog_api_key,
        'Content-Type': 'application/json',
        Authorization: "Bearer #{Setting.three_sixty_dialog_partner_token}"
      }
    end

    def fetch_token
      url = URI.parse("#{base_uri}/token")
      headers = { 'Content-Type': 'application/json' }
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

    def fetch_waba_account_id
      url = URI.parse("#{base_uri}/partners/#{partner_id}/channels")
      headers = {
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{Setting.three_sixty_dialog_partner_token}"
      }
      request = Net::HTTP::Get.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      channels_array = JSON.parse(response.body)['partner_channels']
      client_hash = channels_array.find { |hash| hash['client']['id'] == Setting.three_sixty_dialog_client_id }
      waba_account_id = client_hash['waba_account']['external_id']
      Setting.three_sixty_dialog_client_waba_account_id = waba_account_id
    end

    # rubocop:disable Metrics/MethodLength
    def template_payload
      {
        name: template_name,
        category: 'MARKETING',
        components: [
          {
            type: 'BODY',
            text: template_text,
            example: {
              body_text: [
                [
                  'Jakob',
                  'Familie und Freizeit'
                ]
              ]
            }
          },
          {
            type: 'BUTTONS',
            buttons: [
              {
                type: 'QUICK_REPLY',
                text: 'Antworten'
              },
              {
                type: 'QUICK_REPLY',
                text: 'Mehr Infos'
              }
            ]
          }
        ],
        language: 'de',
        allow_category_change: true
      }
    end
    # rubocop:enable Metrics/MethodLength

    def handle_response(response)
      case response.code.to_i
      when 200
        Rails.logger.debug 'Great!'
      when 400..599
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
