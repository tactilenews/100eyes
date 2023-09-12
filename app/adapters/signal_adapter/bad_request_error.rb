# frozen_string_literal: true

module SignalAdapter
  class BadRequestError < StandardError
    def initialize(error_code:, message:)
      super("Message was not delivered with error code #{error_code} and message #{message}")
    end
  end
end
