# frozen_string_literal: true

module MessageGroupsSkeleton
  class MessageGroupsSkeleton < ApplicationComponent
    def initialize(organization_id:, request_id:)
      super

      @organization_id = organization_id
      @request_id = request_id
    end

    attr_reader :request_id, :organization_id
  end
end
