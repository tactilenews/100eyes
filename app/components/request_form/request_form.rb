# frozen_string_literal: true

module RequestForm
  class RequestForm < ApplicationComponent
    def initialize(organization:, request:, available_tags:)
      super

      @organization = organization
      @request = request
      @available_tags = available_tags
    end

    private

    attr_reader :organization, :request, :available_tags

    def schedule_send_for_or_default
      datetime = request.planned? ? request.schedule_send_for : Time.current
      datetime.strftime('%Y-%m-%dT%H:%M')
    end
  end
end
