# frozen_string_literal: true

module ActivityNotifications
  class ActivityNotifications < ApplicationComponent
    def initialize(notifications: [])
      super

      @notifications = notifications
    end

    attr_reader :notifications
  end
end
