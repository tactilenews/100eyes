module ActivityNotifications
  class ActivityNotifications < ApplicationComponent
    def initialize(notifications: [])
      @notifications = notifications
    end

    attr_reader :notifications
  end
end
