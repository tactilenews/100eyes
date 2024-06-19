# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class ReceivePollingJob < ApplicationJob
    queue_as :poll_signal_messages
    attr_reader :adapter

    before_enqueue do
      throw(:abort) unless queue_empty?
    end

    def perform(*_args)
      return if Setting.signal_server_phone_number.blank?

      signal_messages = request_new_messages
      @adapter = SignalAdapter::Inbound.new

      handle_callbacks

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
      raise SignalAdapter::ServerError if res.instance_of?(Net::HTTPBadRequest)

      JSON.parse(res.body)
    end

    def handle_callbacks
      adapter.on(SignalAdapter::CONNECT) do |contributor|
        handle_connect(contributor)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |signal_uuid|
        exception = SignalAdapter::UnknownContributorError.new(signal_uuid: signal_uuid)
        ErrorNotifier.report(exception)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTENT) do |contributor|
        SignalAdapter::Outbound.send_unknown_content_message!(contributor)
      end

      adapter.on(SignalAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
        UnsubscribeContributorJob.perform_later(contributor.id, SignalAdapter::Outbound)
      end

      adapter.on(SignalAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor|
        ResubscribeContributorJob.perform_later(contributor.id, SignalAdapter::Outbound)
      end

      adapter.on(SignalAdapter::HANDLE_DELIVERY_RECEIPT) do |delivery_receipt, contributor|
        handle_delivery_receipt(delivery_receipt, contributor)
      end
    end

    def ping_monitoring_service
      return if Setting.signal_monitoring_url.blank?

      monitoring_url = URI.parse(Setting.signal_monitoring_url)
      Net::HTTP.get(monitoring_url)
    end

    def queue_empty?
      Delayed::Job.where(queue: queue_name, failed_at: nil).none?
    end

    def handle_connect(contributor, signal_uuid)
      contributor.update!(signal_uuid)
      SignalAdapter::CreateContactJob.perform_later(contributor_id: contributor.id)
      SignalAdapter::AttachContributorsAvatarJob.perform_later(contributor_id: contributor.id)
    end

    def handle_delivery_receipt(signal_message, contributor)
      delivery_receipt = signal_message.dig(:envelope, :receiptMessage)
      signal_uuid = signal_message.dig(:envelope, :sourceUuid)
      handle_connect(contributor, signal_uuid) if contributor.signal_uuid.blank?

      datetime = Time.zone.at(delivery_receipt[:when] / 1000).to_datetime
      latest_received_message = contributor.received_messages.first
      return unless latest_received_message

      latest_received_message.update(received_at: datetime) if delivery_receipt[:isDelivery]
      latest_received_message.update(read_at: datetime) if delivery_receipt[:isRead]
    end
  end
end
