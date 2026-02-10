# frozen_string_literal: true

module SignalAdapter
  class ProcessWebhookJob < ApplicationJob
    def perform(signal_message:)
      handle_invalid_message(signal_message)
      return if typing_message_only?(signal_message)

      organization = initialize_organization(signal_message)
      return unless organization

      contributor = initialize_onboarded_contributor(organization, signal_message)
      delivery_receipt = initialize_delivery_receipt(signal_message, contributor)
      return if delivery_receipt

      unless contributor
        initialize_onboarding_contributor(signal_message, organization)
        return
      end
      adapter = SignalAdapter::Inbound.new

      adapter.consume(contributor, signal_message)
    rescue StandardError => e
      ErrorNotifier.report(e)
    end

    private

    def handle_invalid_message(signal_message)
      exception = signal_message[:exception]
      return unless exception

      error = SignalAdapter::InvalidMessageError.new(
        exception_message: exception[:message],
        exception_type: exception[:type]
      )
      ErrorNotifier.report(error)
    end

    def typing_message_only?(signal_message)
      envelope = signal_message.dig(:envelope)
      return false unless envelope

      has_typing_message = envelope[:typingMessage].present?
      has_data_message = envelope[:dataMessage].present?
      has_reaction = envelope[:reaction].present?

      has_typing_message && !has_data_message && !has_reaction
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

    def signal_onboarding_token(message)
      return unless message.present? && message.strip.length.eql?(8)

      message.strip
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

    def handle_connect(contributor, signal_uuid)
      contributor.update!(signal_uuid: signal_uuid, signal_onboarding_completed_at: Time.current)
      SignalAdapter::CreateContactJob.perform_later(contributor_id: contributor.id)
      SignalAdapter::AttachContributorsAvatarJob.perform_later(contributor_id: contributor.id)
      SignalAdapter::Outbound.send_welcome_message!(contributor)
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

    def update_contributor(contributor, signal_phone_number, signal_uuid)
      contributor.update!(signal_phone_number: signal_phone_number) if signal_phone_number && contributor.signal_phone_number.blank?
      contributor.update!(signal_uuid: signal_uuid) if signal_uuid && contributor.signal_uuid.blank?
    end

    def initialize_onboarded_contributor(organization, signal_message)
      envelope = signal_message[:envelope]
      signal_phone_number = envelope[:sourceNumber]
      signal_uuid = envelope[:sourceUuid]

      contributors = organization.contributors.with_signal
      contributor = if signal_phone_number
                      contributors.find_by(signal_phone_number: signal_phone_number)
                    else
                      contributors.find_by(signal_uuid: signal_uuid)
                    end
      update_contributor(contributor, signal_phone_number, signal_uuid) if contributor
      contributor
    end

    def initialize_delivery_receipt(signal_message, contributor)
      return unless signal_message.dig(:envelope, :receiptMessage).present? && contributor

      delivery_receipt = signal_message.dig(:envelope, :receiptMessage)

      datetime = Time.zone.at(delivery_receipt[:when] / 1000).to_datetime
      received_messages = contributor.received_messages
      receipt_for_message = received_messages.find_by(external_id: delivery_receipt[:timestamps].first) ||
                            received_messages.first
      return unless receipt_for_message

      receipt_for_message.update(delivered_at: datetime) if delivery_receipt[:isDelivery]
      receipt_for_message.update(read_at: datetime) if delivery_receipt[:isRead]
      delivery_receipt
    end
  end
end
