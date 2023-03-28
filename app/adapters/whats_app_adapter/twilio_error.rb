# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioError < StandardError
    def initialize(error_code:)
      super("Error occurred for WhatsApp with error code: #{error_code}")
    end
  end
end
