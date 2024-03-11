# frozen_string_literal: true

module MessageGroupsSkeleton
  class MessageGroupsSkeleton < ApplicationComponent
    def initialize(request_id:)
      super

      @request_id = request_id
    end

    attr_reader :request_id
  end
end
