# frozen_string_literal: true

module ThreeSixtyDialog
  BASE_URI = 'https://hub.360dialog.io/api/v2'
  PARTNER_ID = 'WdBs71PA'

  class Api
    def client_api_key(channel_id)
      uri = URI.parse("#{BASE_URI}/partners/#{PARTNER_ID}/channels/#{channel_id}/api_keys")
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request['Authorization'] = "Bearer #{partner_token}"
      perform_request(request) do |response|
        return JSON.parse(response.body)['api_key']
      end
    end

    def partner_token
      return @partner_token if @partner_token

      uri = URI.parse("#{BASE_URI}/token")
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = {
        username: Setting.three_sixty_dialog_partner_username,
        password: Setting.three_sixty_dialog_partner_password
      }.to_json

      perform_request(request) do |response|
        @partner_token = JSON.parse(response.body)['access_token']
        return @partner_token
      end
    end

    def perform_request(request)
      uri = request.uri
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      case response
      when Net::HTTPSuccess
        yield response
      else
        exception = WhatsAppAdapter::ThreeSixtyDialogError.new(error_code: response.code, message: response.body)
        ErrorNotifier.report(exception)
      end
    end
  end
end
