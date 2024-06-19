# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class CreateContactJob < ApplicationJob
    def perform(contributor_id:)
      contributor = Contributor.find_by(id: contributor_id)
      return unless contributor

      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/contacts/#{Setting.signal_server_phone_number}")
      header = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      }
      data = {
        recipient: contributor.signal_uuid,
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
