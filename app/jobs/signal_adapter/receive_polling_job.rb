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
      return if signal_server_phone_number_not_configured?

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

    def signal_server_phone_number_not_configured?
      Organization.all.all? { |org| org.signal_server_phone_number.blank? }
    end

    def request_new_messages
      registered_signal_server_phone_numbers = Organization.pluck(:signal_server_phone_number).compact
      registered_signal_server_phone_numbers.collect do |phone_number|
        url = URI.parse("#{ENV.fetch('SIGNAL_CLI_REST_API_ENDPOINT', 'http://localhost:8080')}/v1/receive/#{phone_number}")
        res = Net::HTTP.get_response(url)
        raise SignalAdapter::ServerError if res.instance_of?(Net::HTTPBadRequest)

        JSON.parse(res.body)
      end.flatten
    end

    def handle_callbacks
      adapter.on(SignalAdapter::UNKNOWN_ORGANIZATION) do |signal_server_phone_number|
        handle_unknown_organization(signal_server_phone_number)
      end

      adapter.on(SignalAdapter::CONNECT) do |contributor, signal_uuid, organization|
        handle_connect(contributor, signal_uuid, organization)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |signal_attr|
        handle_unknown_contributor(signal_attr)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTENT) do |contributor, organization|
        SignalAdapter::Outbound.send_unknown_content_message!(contributor, organization)
      end

      adapter.on(SignalAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor, organization|
        UnsubscribeContributorJob.perform_later(organization.id, contributor.id, SignalAdapter::Outbound)
      end

      adapter.on(SignalAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor, organization|
        ResubscribeContributorJob.perform_later(organization.id, contributor.id, SignalAdapter::Outbound)
      end

      adapter.on(SignalAdapter::HANDLE_DELIVERY_RECEIPT) do |delivery_receipt, contributor|
        handle_delivery_receipt(delivery_receipt, contributor)
      end
    end

    def ping_monitoring_service
      return if ENV.fetch('SIGNAL_MONITORING_URL', nil).blank?

      monitoring_url = URI.parse(ENV.fetch('SIGNAL_MONITORING_URL', nil))
      Net::HTTP.get(monitoring_url)
    end

    def queue_empty?
      Delayed::Job.where(queue: queue_name, failed_at: nil).none?
    end

    def handle_connect(contributor, signal_uuid, organization)
      contributor.update!(signal_uuid: signal_uuid, signal_onboarding_completed_at: Time.current)
      SignalAdapter::CreateContactJob.perform_later(organization_id: organization.id, contributor_id: contributor.id)
      SignalAdapter::AttachContributorsAvatarJob.perform_later(contributor_id: contributor.id)
      SignalAdapter::Outbound.send_welcome_message!(contributor, organization)
    end

    def handle_delivery_receipt(delivery_receipt, contributor)
      datetime = Time.zone.at(delivery_receipt[:when] / 1000).to_datetime
      latest_received_message = contributor.received_messages.first
      return unless latest_received_message

      latest_received_message.update(delivered_at: datetime) if delivery_receipt[:isDelivery]
      latest_received_message.update(read_at: datetime) if delivery_receipt[:isRead]
    end

    def handle_unknown_contributor(signal_attr)
      exception = SignalAdapter::UnknownContributorError.new(signal_attr: signal_attr)
      ErrorNotifier.report(exception)
    end

    def handle_unknown_organization(signal_server_phone_number)
      exception = SignalAdapter::UnknownOrganizationError.new(signal_server_phone_number: signal_server_phone_number)
      ErrorNotifier.report(exception)
    end
  end
end
