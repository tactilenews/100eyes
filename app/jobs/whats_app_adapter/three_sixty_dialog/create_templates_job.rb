# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class CreateTemplatesJob < ApplicationJob
      attr_reader :organization

      def perform(organization_id:)
        @organization = Organization.find(organization_id)

        existing_templates = WhatsAppAdapter::ThreeSixtyDialog::TemplateFetcherService.call(organization_id: organization.id)

        whats_app_templates = new_request_templates.merge(new_direct_message_template)
        templates_to_create_array = whats_app_templates.keys.difference(existing_templates)
        templates_to_create = whats_app_templates.select { |key, _value| key.in?(templates_to_create_array) }
        templates_to_create.each do |key, value|
          example_body_text = key.eql?(:new_direct_message) ? ['Astrid'] : ['Jackob', 'Familie und Freizeit']
          WhatsAppAdapter::ThreeSixtyDialog::TemplateCreatorService.call(organization_id: organization.id,
                                                                         payload: template_payload(key, value, example_body_text))
        end
      end

      private

      # rubocop:disable Style/FormatStringToken
      def new_request_templates
        I18n.t('.')[:adapter][:whats_app][:request_template].transform_values do |value|
          value.gsub('%{first_name}', '{{1}}').gsub('%{request_title}', '{{2}}')
        end
      end

      def new_direct_message_template
        I18n.t('.')[:adapter][:whats_app][:direct_message_template].transform_values do |value|
          value.gsub('%{first_name}', '{{1}}')
        end
      end
      # rubocop:enable Style/FormatStringToken

      def template_payload(template_name, template_text, example_body_text)
        {
          name: template_name,
          category: 'MARKETING',
          components: [
            {
              type: 'BODY',
              text: template_text,
              example: {
                body_text: [example_body_text]
              }
            },
            quick_reply_buttons
          ],
          language: 'de',
          allow_category_change: true
        }
      end

      def quick_reply_buttons
        {
          type: 'BUTTONS',
          buttons: [
            {
              type: 'QUICK_REPLY',
              text: organization.whats_app_quick_reply_button_text['answer_request']
            },
            {
              type: 'QUICK_REPLY',
              text: organization.whats_app_quick_reply_button_text['more_info']
            }
          ]
        }
      end
    end
  end
end
