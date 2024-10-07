# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  class CreateTemplates < ApplicationJob
    def perform(organization_id:, token:)
      @organization = Organization.find_by(id: organization_id)
      return unless organization

      @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
      @partner_id = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)
      @token = token
      @waba_account_id = organization.three_sixty_dialog_client_waba_account_id
      @waba_account_id = fetch_client_info if waba_account_id.blank? || organization.three_sixty_dialog_whats_app_template_namespace.blank?
      existing_templates = WhatsAppAdapter::ThreeSixtyDialog::TemplateFetcherService.new(
        waba_account_id: waba_account_id,
        token: token
      ).call
      templates_to_create_array = whats_app_templates.keys.difference(existing_templates)
      templates_to_create = whats_app_templates.select { |key, _value| key.in?(templates_to_create_array) }
      templates_to_create.each do |key, value|
        @template_name = key
        @template_text = value

        create_template
      end
    end

    attr_reader :organization, :base_uri, :partner_id, :template_name, :template_text, :token, :waba_account_id

    private

    # rubocop:disable Style/FormatStringToken
    def whats_app_templates
      default_welcome_message = ["*#{File.read(File.join('config', 'locales', 'onboarding', 'success_heading.txt'))}*",
                                 File.read(File.join('config', 'locales', 'onboarding',
                                                     'success_text.txt'))].join("\n\n").gsub('100eyes', '{{1}}')
      default_welcome_message_hash = { default_welcome_message: default_welcome_message }
      requests_hash = I18n.t('.')[:adapter][:whats_app][:request_template].transform_values do |value|
        value.gsub('%{first_name}', '{{1}}').gsub('%{request_title}', '{{2}}')
      end
      default_welcome_message_hash.merge(requests_hash)
    end
    # rubocop:enable Style/FormatStringToken

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
        Accept: 'application/json',
        'Content-Type': 'application/json',
        Authorization: "Bearer #{token}"
      }
    end

    def fetch_client_info
      url = URI.parse("#{base_uri}/partners/#{partner_id}/channels")
      headers = set_headers
      request = Net::HTTP::Get.new(url.to_s, headers)
      response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(request)
      end
      channels_array = JSON.parse(response.body)['partner_channels']
      client_hash = channels_array.find { |hash| hash['client']['id'] == organization.three_sixty_dialog_client_id }
      waba_account = client_hash['waba_account']
      organization.update!(three_sixty_dialog_whats_app_template_namespace: waba_account['namespace'],
                           three_sixty_dialog_client_waba_account_id: waba_account['id'])
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
      case response
      when Net::HTTPSuccess
        Rails.logger.debug 'Great!'
      when Net::HTTPClientError, Net::HTTPServerError
        return if response.body.match?(/you have provided is already in use. Please choose a different name for your template./)

        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
