# frozen_string_literal: true

module SignalAdapter
  class UnknownContributorError < StandardError
    def initialize(signal_uuid:)
      super("Received a message on signal from an unknown sender: #{signal_uuid}")
    end
  end
end
