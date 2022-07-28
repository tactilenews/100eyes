# frozen_string_literal: true

module SignalAdapter
  class ReceivePollingJob
    class ServerError < ErrorNotifier::IgnoredError; end
  end
end
