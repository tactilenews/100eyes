# frozen_string_literal: true

require 'net/http'

module WhatsAppAdapter
  module ThreeSixtyDialog
    class CreateWelcomeMessageTemplateJob < ApplicationJob
      def perform(organization_id:)
        @organization = Organization.find_by(id: organization_id)
        @token = WhatsAppAdapter::ThreeSixtyDialog::TokenFetcherService.new.call

        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        @partner_id = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)
        @waba_account_id = organization.three_sixty_dialog_client_waba_account_id

        if "welcome_message_#{organization.project_name.parameterize.underscore}".in?(existing_templates)
          User.admin.find_each do |admin|
            PostmarkAdapter::Outbound.welcome_message_updated!(admin, organization)
          end
        else
          create_welcome_message_template
        end
      end

      attr_reader :organization, :token, :base_uri, :partner_id, :waba_account_id

      private

      def existing_templates
        url = URI.parse(
          "#{base_uri}/partners/#{partner_id}/waba_accounts/#{waba_account_id}/waba_templates"
        )
        headers = set_headers
        request = Net::HTTP::Get.new(url.to_s, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        waba_templates = JSON.parse(response.body)['waba_templates']
        waba_templates.pluck('name').map(&:to_sym)
      end

      def create_welcome_message_template
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
