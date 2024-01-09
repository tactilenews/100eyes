# frozen_string_literal: true

module WhatsAppAdapter
  class MessageDeliveryUnsuccessfulError < StandardError
    def initialize(status:, whats_app_phone_number:, message:)
      super("Message delivery to #{whats_app_phone_number} was unsuccessful with status: #{status} and message #{message}")
    end
  end
end
