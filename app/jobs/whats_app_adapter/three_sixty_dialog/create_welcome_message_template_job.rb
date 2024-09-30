# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class CreateWelcomeMessageTemplateJob < ApplicationJob
      def perform(organization_id:, template_text:, token:)
        @organization = Organization.find_by(id: organization_id)
        @token = token
        @template_text = template_text

        base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        partner_id = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)
        waba_account_id = organization.three_sixty_dialog_client_waba_account_id
        url = URI.parse(
          "#{base_uri}/partners/#{partner_id}/waba_accounts/#{waba_account_id}/waba_templates"
        )
        headers = set_headers

        request = Net::HTTP::Post.new(url.to_s, headers)
        payload = welcome_message_template_payload
        request.body = payload.to_json
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        handle_response(response)
      end

      attr_reader :organization, :token, :template_text

      private

      def set_headers
        {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: "Bearer #{token}"
        }
      end

      def welcome_message_template_payload
        {
          name: "welcome_message_#{organization.project_name.parameterize.underscore}",
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
    end
  end
end
