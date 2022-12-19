# frozen_string_literal: true

module WhatsAppAdapter
  class UnknownContributorError < StandardError
    def initialize(signal_phone_number:)
      super("Received a message on signal from an unknown sender: #{signal_phone_number}")
    end
  end
end
