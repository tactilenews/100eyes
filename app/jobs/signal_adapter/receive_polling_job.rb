# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class ReceivePollingJob < ApplicationJob
    queue_as :default

    def perform(*_args)
      url = URI.parse("#{Setting.signal_rest_cli_endpoint}/v1/receive/#{Setting.signal_phone_number}")
      req = Net::HTTP::Get.new(url.to_s)
      req['Accept'] = 'application/json'
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      signal_messages = JSON.parse(res.body)

      adapter = SignalAdapter::Inbound.new
      signal_messages.each do |raw_message|
        adapter.consume(raw_message) do |m|
          m.contributor.reply(adapter)
        end
      end
    end
  end
end
