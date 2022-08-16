# frozen_string_literal: true

module ActivityNotifications
  class ActivityNotifications < ApplicationComponent
    def initialize(activity_notifications: [], count_per_request: [])
      super

      @activity_notifications = activity_notifications
      @count_per_request = count_per_request
    end

    attr_reader :activity_notifications, :count_per_request

    def count(request)
      count_per_request.reduce(1) do |accumulator, count_hash|
        key, value = count_hash.first
        key == request ? value : accumulator
      end
    end
  end
end
