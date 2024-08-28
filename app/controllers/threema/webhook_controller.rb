# frozen_string_literal: true

require 'openssl'

class Threema::WebhookController < ApplicationController
  skip_before_action :require_login, :verify_authenticity_token, :user_permitted?, :set_organization

  attr_reader :adapter

  def message
    @adapter = ThreemaAdapter::Inbound.new

    handle_callbacks

    @adapter.consume(threema_webhook_params) do |message|
      message.contributor.reply(adapter)
    end

    head :ok
  rescue ActiveRecord::RecordInvalid
    head :service_unavailable
  end

  private

  def threema_webhook_params
    params.permit(:from, :to, :messageId, :date, :nonce, :box, :mac, :nickname)
  end

  def handle_callbacks
    adapter.on(ThreemaAdapter::UNKNOWN_ORGANIZATION) do |threemarb_api_identity|
      exception = ThreemaAdapter::UnknownOrganizationError.new(threemarb_api_identity: threemarb_api_identity)
      ErrorNotifier.report(exception)
    end

    adapter.on(ThreemaAdapter::UNKNOWN_CONTRIBUTOR) do |threema_id|
      exception = ThreemaAdapter::UnknownContributorError.new(threema_id: threema_id)
      ErrorNotifier.report(exception)
    end

    adapter.on(ThreemaAdapter::HANDLE_DELIVERY_RECEIPT) do |delivery_receipt|
      handle_delivery_receipt(delivery_receipt)
    end

    adapter.on(ThreemaAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor, organization|
      UnsubscribeContributorJob.perform_later(organization.id, contributor.id, ThreemaAdapter::Outbound)
    end

    adapter.on(ThreemaAdapter::RESUBSCRIBE_CONTRIBUTOR) do |contributor, organization|
      ResubscribeContributorJob.perform_later(organization.id, contributor.id, ThreemaAdapter::Outbound)
    end

    adapter.on(ThreemaAdapter::UNSUPPORTED_CONTENT) do |contributor, organization|
      ThreemaAdapter::Outbound.send_unsupported_content_message!(contributor, organization)
    end
  end

  def handle_delivery_receipt(delivery_receipt)
    return if delivery_receipt.message_ids.blank?

    messages = Message.where(external_id: delivery_receipt.message_ids)
    messages.each do |message|
      delivery_receipt.message_ids.each do |message_id|
        next unless message.external_id.eql?(message_id)

        local_datetime = Time.zone.at(delivery_receipt.timestamp).to_datetime

        message.update(received_at: local_datetime) if delivery_receipt.status.eql?(:received)

        next unless delivery_receipt.status.eql?(:read)

        message.read_at = local_datetime
        message.received_at = local_datetime if message.received_at.blank?
        message.save
      end
    end
  end
end
