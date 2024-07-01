# frozen_string_literal: true

module WhatsAppAdapter
  class UnknownOrganizationError < StandardError
    def initialize(whats_app_server_phone_number:)
      super("Received a message on WhatsApp to an unknown organization: #{whats_app_server_phone_number}")
    end
  end
end
