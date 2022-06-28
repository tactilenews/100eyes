# frozen_string_literal: true

module SignalAdapter
  class Outbound < ApplicationJob
    queue_as :default
    ServerException = Class.new(StandardError)

    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      perform_later(text: message.text, recipient: recipient)
    end

    def self.send_welcome_message!(contributor)
      return unless contributor_can_receive_messages?(contributor)

      welcome_message = [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(text:, recipient:)
      url = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v2/send")
      header = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      }
      data = {
        number: Setting.signal_server_phone_number,
        recipients: [recipient.signal_phone_number],
        message: text
      }
      req = Net::HTTP::Post.new(url.to_s, header)
      req.body = data.to_json
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      res.value # may raise exception
    rescue Net::HTTPServerException => e
      ErrorNotifier.report(ServerException.new, context: {
                             original_exception: e,
                             code: e.response.code,
                             message: e.response.message,
                             headers: e.response.to_hash,
                             body: e.response.body
                           })
    end

    def self.contributor_can_receive_messages?(recipient)
      recipient&.signal_phone_number.present? && recipient.signal_onboarding_completed_at.present?
    end
  end
end
