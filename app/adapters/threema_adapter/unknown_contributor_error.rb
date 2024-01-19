# frozen_string_literal: true

module ThreemaAdapter
  class UnknownContributorError < StandardError
    def initialize(threema_id:)
      super("Received a message on Threema from an unknown sender: #{threema_id}")
    end
  end
end
