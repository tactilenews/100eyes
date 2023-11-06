# frozen_string_literal: true

require 'net/http'

module SignalAdapter
  class ReceivePollingJob < ApplicationJob
    queue_as :poll_signal_messages

    before_enqueue do
      throw(:abort) unless queue_empty?
    end

    # rubocop:disable Metrics/MethodLength
    def perform(*_args)
      return if Setting.signal_server_phone_number.blank?

      signal_messages = request_new_messages
      adapter = SignalAdapter::Inbound.new

      adapter.on(SignalAdapter::CONNECT) do |contributor|
        handle_connect(contributor)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTRIBUTOR) do |signal_phone_number|
        exception = SignalAdapter::UnknownContributorError.new(signal_phone_number: signal_phone_number)
        ErrorNotifier.report(exception)
      end

      adapter.on(SignalAdapter::UNKNOWN_CONTENT) do |contributor|
        SignalAdapter::Outbound.send_unknown_content_message!(contributor)
      end

      adapter.on(SignalAdapter::UNSUBSCRIBE_CONTRIBUTOR) do |contributor|
        handle_unsubscribe_contributor(contributor)
      end

      adapter.on(SignalAdapter::SUBSCRIBE_CONTRIBUTOR) do |contributor|
        handle_subscribe_contributor(contributor)
      end

      adapter.on(SignalAdapter::HANDLE_DELIVERY_RECEIPT) do |delivery_receipt, contributor|
        handle_delivery_receipt(delivery_receipt, contributor)
      end

      signal_messages.each do |raw_message|
        adapter.consume(raw_message) { |m| m.contributor.reply(adapter) }
      rescue StandardError => e
        ErrorNotifier.report(e)
      end

      ping_monitoring_service && return
    end
    # rubocop:enable Metrics/MethodLength

    private

    def request_new_messages
      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v1/receive/#{Setting.signal_server_phone_number}")
      res = Net::HTTP.get_response(url)
      raise SignalAdapter::ServerError if res.instance_of?(Net::HTTPBadRequest)

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

    def handle_connect(contributor)
      contributor.update!(signal_onboarding_completed_at: Time.zone.now)
      SignalAdapter::Outbound.send_welcome_message!(contributor)
      SignalAdapter::AttachContributorsAvatarJob.perform_later(contributor)
    end

    def handle_unsubscribe_contributor(contributor)
      contributor.update!(deactivated_at: Time.current)
      SignalAdapter::Outbound.send_unsubsribed_successfully_message!(contributor)
      ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
      User.admin.find_each do |admin|
        PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
      end
    end

    def handle_subscribe_contributor(contributor)
      if contributor.deactivated_by_user.present?
        exception = StandardError.new(
          "Contributor #{contributor.name} has been deactivated by #{contributor.deactivated_by_user.name} and has tried to re-subscribe"
        )
        ErrorNotifier.report(exception)
        return
      end

      contributor.update!(deactivated_at: nil)
      SignalAdapter::Outbound.send_welcome_message!(contributor)
      ContributorSubscribed.with(contributor_id: contributor.id).deliver_later(User.all)
      User.admin.find_each do |admin|
        PostmarkAdapter::Outbound.contributor_subscribed!(admin, contributor)
      end
    end

    def handle_delivery_receipt(delivery_receipt, contributor)
      datetime = Time.zone.at(delivery_receipt[:when] / 1000).to_datetime
      latest_received_message = contributor.received_messages.first
      latest_received_message.update(received_at: datetime) if delivery_receipt[:isDelivery]
      latest_received_message.update(read_at: datetime) if delivery_receipt[:isRead]
    end
  end
end
