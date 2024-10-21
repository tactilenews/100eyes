# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class CreateTemplatesJob < ApplicationJob
      def perform(organization_id:)
        @organization = Organization.find(organization_id)

        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        existing_templates = WhatsAppAdapter::ThreeSixtyDialog::TemplateFetcherService.new(organization_id: organization.id).call

        templates_to_create_array = whats_app_templates.keys.difference(existing_templates)
        templates_to_create = whats_app_templates.select { |key, _value| key.in?(templates_to_create_array) }
        templates_to_create.each do |key, value|
          @template_name = key
          @template_text = value
          WhatsAppAdapter::ThreeSixtyDialog::TemplateCreatorService.new(organization_id: organization.id,
                                                                        payload: new_request_template_payload).call
        end
      end

      attr_reader :organization, :base_uri, :partner_id, :template_name, :template_text, :token, :waba_account_id

      private

      # rubocop:disable Style/FormatStringToken
      def whats_app_templates
        I18n.t('.')[:adapter][:whats_app][:request_template].transform_values do |value|
          value.gsub('%{first_name}', '{{1}}').gsub('%{request_title}', '{{2}}')
        end
      end
      # rubocop:enable Style/FormatStringToken

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
    end
  end
end
