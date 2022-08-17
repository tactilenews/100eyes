# frozen_string_literal: true

module ActivityNotifications
  class ActivityNotifications < ApplicationComponent
    delegate :current_user, to: :helpers

    def initialize(activity_notifications: [])
      super

      @activity_notifications = activity_notifications
    end

    attr_reader :activity_notifications
  end
end
