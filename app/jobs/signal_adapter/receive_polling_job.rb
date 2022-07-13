# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class ReceivePollingJob < ApplicationJob
    queue_as :poll_signal_messages

    before_enqueue do
      throw(:abort) unless queue_empty?
    end

    def perform(*_args)
      return if Setting.signal_server_phone_number.blank?

      signal_messages = request_new_messages
      adapter = SignalAdapter::Inbound.new

      adapter.on(SignalAdapter::CONNECT) do |contributor|
        contributor.update!(signal_onboarding_completed_at: Time.zone.now)
        SignalAdapter::Outbound.send_welcome_message!(contributor)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |signal_phone_number|
        exception = SignalAdapter::UnknownContributorError.new(signal_phone_number: signal_phone_number)
        ErrorNotifier.report(exception)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTENT) do |contributor|
        SignalAdapter::Outbound.perform_later(recipient: contributor, text: Setting.signal_unknown_content_message)
      end

      signal_messages.each do |raw_message|
        adapter.consume(raw_message) { |m| m.contributor.reply(adapter) }
      rescue StandardError => e
        ErrorNotifier.report(e)
      end

      ping_monitoring_service && return
    end

    private

    def request_new_messages
      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/receive/#{Setting.signal_server_phone_number}")
      res = Net::HTTP.get_response(url)
      JSON.parse(res.body)
    end

    def ping_monitoring_service
      return if Setting.signal_monitoring_url.blank?

      monitoring_url = URI.parse(Setting.signal_monitoring_url)
      Net::HTTP.get(monitoring_url)
    end

    def queue_empty?
      Delayed::Job.where(queue: queue_name, failed_at: nil).none?
    end
  end
end
