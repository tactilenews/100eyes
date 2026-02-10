# frozen_string_literal: true

module SignalAdapter
  class InvalidMessageError < StandardError
    def initialize(exception_message:, exception_type:)
      super("Received an invalid Signal message: #{exception_type} - #{exception_message}")
    end
  end
end
