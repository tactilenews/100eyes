# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class CreateTemplatesJob < ApplicationJob
      def perform(organization_id:)
        organization = Organization.find(organization_id)

        existing_templates = WhatsAppAdapter::ThreeSixtyDialog::TemplateFetcherService.call(organization_id: organization.id)

        templates_to_create_array = whats_app_templates.keys.difference(existing_templates)
        templates_to_create = whats_app_templates.select { |key, _value| key.in?(templates_to_create_array) }
        templates_to_create.each do |key, value|
          WhatsAppAdapter::ThreeSixtyDialog::TemplateCreatorService.call(organization_id: organization.id,
                                                                         payload: new_request_template_payload(key, value))
        end
      end

      private

      # rubocop:disable Style/FormatStringToken
      def whats_app_templates
        I18n.t('.')[:adapter][:whats_app][:request_template].transform_values do |value|
          value.gsub('%{first_name}', '{{1}}').gsub('%{request_title}', '{{2}}')
        end
      end
      # rubocop:enable Style/FormatStringToken

      # rubocop:disable Metrics/MethodLength
      def new_request_template_payload(template_name, template_text)
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
