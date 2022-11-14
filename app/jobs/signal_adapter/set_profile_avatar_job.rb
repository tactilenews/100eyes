# frozen_string_literal: true

require 'net/http'
require 'base64'

module SignalAdapter
  class SetProfileAvatarJob < ApplicationJob
    URL = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/profiles/#{Setting.signal_server_phone_number}")

    def perform
      return unless Setting.channel_image

      req = Net::HTTP::Put.new(URL.to_s, {
                                 Accept: 'application/json',
                                 'Content-Type': 'application/json'
                               })
      req.body = {
        base64_avatar: Base64.encode64(File.open(ActiveStorage::Blob.service.path_for(Setting.channel_image.key), 'rb').read),
        name: Setting.project_name
      }.to_json
      http_request.value
    rescue Net::HTTPServerException => e
      ErrorNotifier.report(e, context: {
                             code: e.response.code,
                             message: e.response.message,
                             headers: e.response.to_hash,
                             body: e.response.body
                           })
    end

    def http_request
      Net::HTTP.start(URL.host, URL.port) do |http|
        http.request(req)
      end
    end
  end
end
