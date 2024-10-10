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
          create_welcome_message_template
        end
      end

      attr_reader :organization, :base_uri

      private

      def notify_admin_to_update_existing_template
        User.admin.find_each { |admin| PostmarkAdapter::Outbound.welcome_message_updated!(admin, organization) }
      end

      def create_welcome_message_template
        url = URI.parse("#{base_uri}/v1/configs/templates")
        headers = { 'D360-API-KEY' => organization.three_sixty_dialog_client_api_key, 'Content-Type' => 'application/json' }

        request = Net::HTTP::Post.new(url.to_s, headers)
        payload = welcome_message_template_payload
        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      def welcome_message_template_payload
        {
          name: "welcome_message_#{organization.project_name.parameterize.underscore}",
          category: 'MARKETING',
          components: [
            {
              type: 'BODY',
              text: ["*#{organization.onboarding_success_heading}*", organization.onboarding_success_text].join("\n\n").gsub(
                organization.project_name.to_s, '{{1}}'
              ),
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
          WhatsAppTemplateCreated.with(organization_id: organization.id).deliver_later(organization.users + User.admin.all)
        when Net::HTTPClientError, Net::HTTPServerError
          exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
          ErrorNotifier.report(exception)
        end
      end
    end
  end
end
