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
      signal_messages.each do |message|
        Rails.logger.debug message
      end
      @adapter = SignalAdapter::Inbound.new

      signal_messages.each do |raw_message|
        consume_signal_message(raw_message)
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

    def consume_signal_message(raw_message)
      signal_message = raw_message.with_indifferent_access
      organization = initialize_organization(signal_message)
      return unless organization

      contributor = initialize_onboarded_contributor(organization, signal_message)
      delivery_receipt = initialize_delivery_receipt(signal_message, contributor)
      return if delivery_receipt

      unless contributor
        initialize_onboarding_contributor(signal_message, organization)
        return
      end
      adapter.consume(contributor, signal_message)
    rescue StandardError => e
      ErrorNotifier.report(e)
    end

    def initialize_organization(signal_message)
      signal_server_phone_number = signal_message[:account]
      organization = Organization.find_by(signal_server_phone_number: signal_server_phone_number)
      unless organization
        exception = SignalAdapter::UnknownOrganizationError.new(signal_server_phone_number: signal_server_phone_number)
        ErrorNotifier.report(exception)
      end
      organization
    end

    def initialize_onboarded_contributor(organization, signal_message)
      envelope = signal_message[:envelope]
      source = envelope[:source] || envelope[:sourceNumber] || source[:sourceUuid]
      contributors = organization.contributors.with_signal
      contributors.where(signal_phone_number: source).or(contributors.where(signal_uuid: source)).first
    end

    def initialize_delivery_receipt(signal_message, contributor)
      return unless signal_message.dig(:envelope, :receiptMessage).present? && contributor

      delivery_receipt = signal_message.dig(:envelope, :receiptMessage)

      datetime = Time.zone.at(delivery_receipt[:when] / 1000).to_datetime
      received_messages = contributor.received_messages
      receipt_for_message = received_messages.find_by(external_id: delivery_receipt[:when]) ||
                            received_messages.first
      return unless receipt_for_message

      receipt_for_message.update(delivered_at: datetime) if delivery_receipt[:isDelivery]
      receipt_for_message.update(read_at: datetime) if delivery_receipt[:isRead]
      delivery_receipt
    end

    def initialize_onboarding_contributor(signal_message, organization)
      signal_uuid = signal_message.dig(:envelope, :sourceUuid)
      valid_signal_onboarding_token = signal_onboarding_token(signal_message.dig(:envelope, :dataMessage, :message))
      contributor =
        (organization.contributors.find_by(signal_onboarding_token: valid_signal_onboarding_token) if valid_signal_onboarding_token)

      unless contributor
        handle_unknown_contributor(signal_message, organization)
        return
      end
      return unless signal_uuid

      handle_connect(contributor, signal_uuid)
    end

    def signal_onboarding_token(message)
      return unless message.present? && message.strip.length.eql?(8)

      message.strip
    end

    def handle_connect(contributor, signal_uuid)
      contributor.update!(signal_uuid: signal_uuid, signal_onboarding_completed_at: Time.current)
      SignalAdapter::CreateContactJob.perform_later(contributor_id: contributor.id)
      SignalAdapter::AttachContributorsAvatarJob.perform_later(contributor_id: contributor.id)
      SignalAdapter::Outbound.send_welcome_message!(contributor)
    end

    def handle_unknown_contributor(signal_message, organization)
      envelope = signal_message[:envelope]
      context = {
        message: envelope.dig(:dataMessage, :message) ||
                 envelope.dig(:dataMessage, :reaction, :emoji),
        organization_id: organization.id
      }
      exception = SignalAdapter::UnknownContributorError.new(signal_attr: envelope[:source])
      ErrorNotifier.report(exception, context: context)
    end

    def ping_monitoring_service
      return if ENV.fetch('SIGNAL_MONITORING_URL', nil).blank?

      monitoring_url = URI.parse(ENV.fetch('SIGNAL_MONITORING_URL', nil))
      Net::HTTP.get(monitoring_url)
    end

    def queue_empty?
      Delayed::Job.where(queue: queue_name, failed_at: nil).none?
    end
  end
end
