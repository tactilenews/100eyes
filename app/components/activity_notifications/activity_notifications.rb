# frozen_string_literal: true

module ActivityNotifications
  class ActivityNotifications < ApplicationComponent
    def initialize(organization:, activity_notifications: [])
      super

      @organization = organization
      @activity_notifications = activity_notifications
    end

    attr_reader :organization, :activity_notifications
  end
end
