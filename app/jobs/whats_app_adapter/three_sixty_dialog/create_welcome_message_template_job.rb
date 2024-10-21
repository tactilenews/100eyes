# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class CreateWelcomeMessageTemplateJob < ApplicationJob
      def perform(organization_id:)
        @organization = Organization.find_by(id: organization_id)

        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_WHATS_APP_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        existing_templates = WhatsAppAdapter::ThreeSixtyDialog::TemplateFetcherService.new(organization_id: organization.id).call

        if "welcome_message_#{organization.project_name.parameterize.underscore}".in?(existing_templates)
          notify_admin_to_update_existing_template
        else
          WhatsAppAdapter::ThreeSixtyDialog::TemplateCreatorService.new(organization_id: organization.id,
                                                                        payload: welcome_message_template_payload).call
        end
      end

      attr_reader :organization, :base_uri

      private

      def notify_admin_to_update_existing_template
        User.admin.find_each { |admin| PostmarkAdapter::Outbound.welcome_message_updated!(admin, organization) }
      end

      def welcome_message_template_payload
        {
          name: "welcome_message_#{organization.project_name.parameterize.underscore}",
          category: 'MARKETING',
          components: [
            {
              type: 'BODY',
              text: ["*#{organization.onboarding_success_heading}*", organization.onboarding_success_text].join("\n\n")
            }
          ],
          language: 'de',
          allow_category_change: true
        }
      end
    end
  end
end
