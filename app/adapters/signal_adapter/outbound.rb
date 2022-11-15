# frozen_string_literal: true

module SignalAdapter
  class Outbound < ApplicationJob
    queue_as :default

    attr_reader :message, :recipient, :data

    URL = URI.parse("#{Setting.signal_cli_rest_api_endpoint}/v2/send")

    def self.send!(message)
      recipient = message&.recipient
      return unless contributor_can_receive_messages?(recipient)

      perform_later(message: message, recipient: recipient)
    end

    def self.send_welcome_message!(contributor)
      return unless contributor_can_receive_messages?(contributor)

      welcome_message = [Setting.onboarding_success_heading, Setting.onboarding_success_text].join("\n")
      perform_later(text: welcome_message, recipient: contributor)
    end

    def perform(message:, recipient:)
      @message = message
      @recipient = recipient
      @data = default_data
      merge_attachment if message.request.image.attached?
      req = Net::HTTP::Post.new(URL.to_s, {
                                  Accept: 'application/json',
                                  'Content-Type': 'application/json'
                                })
      req.body = data.to_json
      res = Net::HTTP.start(URL.host, URL.port) do |http|
        http.request(req)
      end
      res.value # may raise exception
    rescue Net::HTTPClientException => e
      ErrorNotifier.report(e, context: {
                             code: e.response.code,
                             message: e.response.message,
                             headers: e.response.to_hash,
                             body: e.response.body
                           })
    end

    def self.contributor_can_receive_messages?(recipient)
      recipient&.signal_phone_number.present? && recipient.signal_onboarding_completed_at.present?
    end

    def default_data
      {
        number: Setting.signal_server_phone_number,
        recipients: [recipient.signal_phone_number],
        message: message.text
      }
    end

    def merge_attachment
      data.merge!(base64_attachments: [Base64.encode64(File.open(ActiveStorage::Blob.service.path_for(message.request.image.blob.key),
                                                                 'rb').read)])
    end
  end
end
