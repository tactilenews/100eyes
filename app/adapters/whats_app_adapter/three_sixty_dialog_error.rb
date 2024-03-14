# frozen_string_literal: true

module WhatsAppAdapter
  class ThreeSixtyDialogError < StandardError
    def initialize(error_code:, message:)
      super("Error occurred for WhatsApp with error code: #{error_code} with message: #{message}")
    end
  end
end
