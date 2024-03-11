# frozen_string_literal: true

module MessageGroups
  class MessageGroups < ApplicationComponent
    def initialize(request:, message_groups: [])
      super

      @request = request
      @message_groups = message_groups
    end

    attr_reader :request, :message_groups
  end
end
