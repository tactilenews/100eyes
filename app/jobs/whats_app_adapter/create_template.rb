# frozen_string_literal: true

require 'net/http'

# rubocop:disable Metrics/ClassLength
module WhatsAppAdapter
  class CreateTemplate < ApplicationJob
    def perform(template_name:, template_text:)
      @base_uri = Setting.three_sixty_dialog_partner_rest_api_endpoint
      @partner_id = Setting.three_sixty_dialog_partner_id
      @template_name = template_name
      @template_text = template_text

      @token = Setting.find_by(var: 'three_sixty_dialog_partner_token')
      @token = fetch_token unless token&.value && token.updated_at > 24.hours.ago

      @waba_account_id = Setting.three_sixty_dialog_client_waba_account_id
      waba_accont_namespace = Setting.three_sixty_dialog_whats_app_template_namespace
      @waba_account_id = fetch_client_info if waba_account_id.blank? || waba_accont_namespace.blank?

      conditionally_create_template
    end

    attr_reader :base_uri, :partner_id, :template_name, :template_text, :token, :waba_account_id

    private

    def conditionally_create_template
      url = URI.parse(
        "#{base_uri}/partners/#{partner_id}/waba_accounts/#{waba_account_id}/waba_templates"
      )
      headers = set_headers
      request = Net::HTTP::Get.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      waba_templates = JSON.parse(response.body)['waba_templates']
      template_names_array = waba_templates.pluck('name')
      return if template_name.in?(template_names_array)

      create_template
    end

    def create_template
      url = URI.parse(
        "#{base_uri}/partners/#{partner_id}/waba_accounts/#{waba_account_id}/waba_templates"
      )
      headers = set_headers

      request = Net::HTTP::Post.new(url.to_s, headers)
      payload = template_name.match?(/welcome_message/) ? welcome_message_template_payload : new_request_template_payload
      request.body = payload.to_json
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      handle_response(response)
    end

    def set_headers
      {
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

    def fetch_client_info
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
      waba_account = client_hash['waba_account']
      Setting.three_sixty_dialog_whats_app_template_namespace = waba_account['namespace']

      Setting.three_sixty_dialog_client_waba_account_id = waba_account['id']
    end

    # rubocop:disable Metrics/MethodLength
    def new_request_template_payload
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

    def welcome_message_template_payload
      {
        name: template_name,
        category: 'MARKETING',
        components: [
          {
            type: 'BODY',
            text: template_text,
            example: {
              body_text: [
                ['100eyes']
              ]
            }
          }
        ],
        language: 'de',
        allow_category_change: true
      }
    end

    def handle_response(response)
      case response.code.to_i
      when 201
        Rails.logger.debug 'Great!'
      when 400..599
        return if response.body.match?(/you have provided is already in use. Please choose a different name for your template./)

        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
