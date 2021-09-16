# frozen_string_literal: true

module SignalAdapter
  class Outbound < ApplicationJob
    queue_as :default
    def self.send!(message)
      recipient = message.recipient
      return unless recipient&.phone_number

      perform_later(text: message.text, recipient: recipient)
    end

    def self.send_welcome_message!(contributor)
      return unless contributor&.phone_number

      welcome_message = ["<b>#{Setting.onboarding_success_heading}</b>", Setting.onboarding_success_text].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(text:, recipient:)
      url = URI.parse("#{Setting.signal_rest_cli_endpoint}/v2/send")
      header = {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      }
      data = {
        number: Setting.signal_phone_number,
        recipients: [recipient.phone_number],
        message: text
      }
      req = Net::HTTP::Post.new(url.to_s, header)
      req.body = data.to_json
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.request(req)
      end
      res.value # may raise exception
    end
  end
end
