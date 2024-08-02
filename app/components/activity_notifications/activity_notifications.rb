# frozen_string_literal: true

module ActivityNotifications
  class ActivityNotifications < OrganizationComponent
    def initialize(activity_notifications: [])
      super

      @activity_notifications = activity_notifications
    end

    attr_reader :activity_notifications
  end
end
