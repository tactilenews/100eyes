# frozen_string_literal: true

module ActivityNotifications
  class ActivityNotifications < ApplicationComponent
    def initialize(activity_notifications: [], count_per_request: [])
      super

      @activity_notifications = activity_notifications
      @count_per_request = count_per_request
    end

    attr_reader :activity_notifications, :count_per_request
  end
end
