# frozen_string_literal: true

module MessageGroupsSkeleton
  class MessageGroupsSkeleton < ApplicationComponent
    def initialize(request_id:, organization:)
      super

      @request_id = request_id
      @organization = organization
    end

    attr_reader :request_id, :organization
  end
end
