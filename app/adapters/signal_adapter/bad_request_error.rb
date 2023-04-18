# frozen_string_literal: true

module SignalAdapter
  class BadRequestError < StandardError
    def initialize(url:)
      super("Bad Reqest to url: #{url}")
    end
  end
end
