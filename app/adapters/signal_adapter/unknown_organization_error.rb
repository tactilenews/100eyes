# frozen_string_literal: true

module SignalAdapter
  class UnknownOrganizationError < StandardError
    def initialize(signal_server_phone_number:)
      super("Received a message on signal to an unknown organization: #{signal_server_phone_number}")
    end
  end
end
