# frozen_string_literal: true

module WhatsAppAdapter
  class TwilioError < StandardError
    def initialize(error_code:, message: nil, url: nil)
      error_text = "Error occurred for WhatsApp with error code: #{error_code}"
      error_text.concat(" with message: #{message}") if message
      error_text.concat(" originated from url #{url}") if url
      super(error_text)
    end
  end
end
