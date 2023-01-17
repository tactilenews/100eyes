# frozen_string_literal: true

module WhatsAppAdapter
  class UnknownContributorError < StandardError
    def initialize(whats_app_phone_number:)
      super("Received a message on WhatsApp from an unknown sender: #{whats_app_phone_number}")
    end
  end
end
