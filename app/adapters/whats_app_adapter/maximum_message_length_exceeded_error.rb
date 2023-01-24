# frozen_string_literal: true

module WhatsAppAdapter
  class MaximumMessageLengthExceededError < StandardError
    def initialize(text:, server_phone_number:)
      super("#{text} Error occurred for WhatsApp Sender: #{server_phone_number}")
    end
  end
end
