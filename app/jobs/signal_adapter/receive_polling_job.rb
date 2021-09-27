# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class ReceivePollingJob < ApplicationJob
    include SuckerPunch::Job
    queue_as :default
    max_jobs 1

    def perform(*_args)
      return if Setting.signal_server_phone_number.blank?

      url = URI.parse("#{Setting.signal_rest_cli_endpoint}/v1/receive/#{Setting.signal_server_phone_number}")
      res = Net::HTTP.get_response(url)
      signal_messages = JSON.parse(res.body)

      adapter = SignalAdapter::Inbound.new

      adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |signal_phone_number|
        exception = SignalAdapter::UnknownContributorError.new(signal_phone_number: signal_phone_number)
        Sentry.capture_exception(exception)
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
