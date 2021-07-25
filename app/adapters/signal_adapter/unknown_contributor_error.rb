# frozen_string_literal: true

module SignalAdapter
  class UnknownContributorError < StandardError
    def initialize(phone_number:)
      super("Received a message on signal from an unknown sender: #{phone_number}")
    end
  end
end
