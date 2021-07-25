# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class ReceivePollingJob < ApplicationJob
    include SuckerPunch::Job
    queue_as :default
    max_jobs 1

    def perform(*_args)
      return if Setting.signal_phone_number.blank?

      url = URI.parse("#{Setting.signal_rest_cli_endpoint}/v1/receive/#{Setting.signal_phone_number}")
      req = Net::HTTP::Get.new(url.to_s)
      req['Accept'] = 'application/json'
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      signal_messages = JSON.parse(res.body)

      adapter = SignalAdapter::Inbound.new

      adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |phone_number|
        raise SignalAdapter::UnknownContributorError.new(phone_number: phone_number)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTENT) do |contributor|
        SignalAdapter::Outbound.perform_later(recipient: contributor, text: Setting.signal_unknown_content_message)
      end

      signal_messages.each do |raw_message|
        adapter.consume(raw_message) do |m|
          m.contributor.reply(adapter)
        end
      end
    end
  end
end
