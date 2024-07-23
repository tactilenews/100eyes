# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class CreateContactJob < ApplicationJob
    def perform(organization_id:, contributor_id:)
      organization = Organization.find_by(id: organization_id)
      return unless organization

      contributor = organization.contributors.find_by(id: contributor_id)
      return unless contributor

      url = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/contacts/#{organization.signal_server_phone_number}")
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
      response = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      handle_response(response)
    end

    def handle_response(response)
      case response.code.to_i
      when 201
        Rails.logger.debug 'Great!'
      when 400..599
        exception = SignalAdapter::ServerError
        ErrorNotifier.report(exception)
      end
    end
  end
end
