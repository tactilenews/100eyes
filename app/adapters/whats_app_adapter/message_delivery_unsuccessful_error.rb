# frozen_string_literal: true

module WhatsAppAdapter
  class MessageDeliveryUnsuccessfulError < StandardError
    def initialize(status:, whats_app_phone_number:)
      super("Message delivery to #{whats_app_phone_number} was unsuccessful with status: #{status}")
    end
  end
end
