# frozen_string_literal: true

module ThreemaAdapter
  class UnknownOrganizationError < StandardError
    def initialize(threemarb_api_identity:)
      super("Received a message on Threema to an unknown organization: #{threemarb_api_identity}")
    end
  end
end
