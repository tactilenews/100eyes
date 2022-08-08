# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class CreateContactJob < ApplicationJob
    queue_as :create_signal_contact

    def perform(contributor)
      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/contacts/#{Setting.signal_server_phone_number}")
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
    end
  end
end
