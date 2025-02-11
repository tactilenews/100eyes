# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class SetProfileInfoJob < ApplicationJob
    attr_reader :organization

    def perform(organization_id:)
      @organization = Organization.find(organization_id)
      return if organization.signal_server_phone_number.blank?

      uri = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/profiles/#{organization.signal_server_phone_number}")
      request = Net::HTTP::Put.new(uri, {
                                     Accept: 'application/json',
                                     'Content-Type': 'application/json'
                                   })

      request.body = update_profile_payload.to_json
      response = Net::HTTP.start(uri.host, uri.port) do |http|
        http.request(request)
      end
      case response
      when Net::HTTPSuccess
        Rails.logger.debug 'Successfully set profile info job!'
      else
        handle_error(response)
      end
    end

    private

    def update_profile_payload
      {
        base64_avatar: Base64.encode64(
          File.open(ActiveStorage::Blob.service.path_for(organization.channel_image.attachment.blob.key), 'rb').read
        ),
        name: organization.project_name,
        about: organization.messengers_about_text
      }
    end

    def handle_error(response)
      error_message = JSON.parse(response.body)['error']
      exception = SignalAdapter::BadRequestError.new(error_code: response.code, message: error_message)
      context = {
        code: response.code,
        message: response.message,
        headers: response.to_hash,
        body: error_message
      }
      ErrorNotifier.report(exception, context: context)
    end
  end
end
