# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class CreateContactJob < ApplicationJob
    def perform(contributor, organization)
      signal_server_phone_number = organization.signal_server_phone_number || Setting.signal_server_phone_number
      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/contacts/#{signal_server_phone_number}")
      header = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      }
      data = {
        recipient: contributor.signal_phone_number,
        name: contributor.name
      }
      req = Net::HTTP::Put.new(url.to_s, header)
      req.body = data.to_json
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      res.value
    rescue Net::HTTPServerException => e
      ErrorNotifier.report(e, context: {
                             code: e.response.code,
                             message: e.response.message,
                             headers: e.response.to_hash,
                             body: e.response.body
                           })
    end
  end
end
