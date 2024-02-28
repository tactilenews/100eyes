# frozen_string_literal: true

module MessageGroups
  class MessageGroups < ApplicationComponent
    def initialize(request:, message_groups: [], path: nil)
      super

      @request = request
      @message_groups = message_groups
      @path = path
    end

    attr_reader :request, :message_groups, :path
  end
end
