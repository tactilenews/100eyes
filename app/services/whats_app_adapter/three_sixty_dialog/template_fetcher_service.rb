# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class TemplateFetcherService
      def initialize(waba_account_id:, token:)
        @base_uri = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_REST_API_ENDPOINT', 'https://stoplight.io/mocks/360dialog/360dialog-partner-api/24588693')
        @partner_id = ENV.fetch('THREE_SIXTY_DIALOG_PARTNER_ID', nil)
        @waba_account_id = waba_account_id
        @token = token
      end

      attr_reader :base_uri, :partner_id, :waba_account_id, :token

      def call
        url = URI.parse(
          "#{base_uri}/partners/#{partner_id}/waba_accounts/#{waba_account_id}/waba_templates"
        )
        headers = {
          Accept: 'application/json',
          'Content-Type': 'application/json',
          Authorization: "Bearer #{token}"
        }
        request = Net::HTTP::Get.new(url.to_s, headers)
        response = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
          http.request(request)
        end
        waba_templates = JSON.parse(response.body)['waba_templates']
        waba_templates.pluck('name').map(&:to_sym)
      end
    end
  end
end
