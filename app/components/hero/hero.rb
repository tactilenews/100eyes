# frozen_string_literal: true

module Hero
  class Hero < ApplicationComponent
    def initialize(activity_notifications: [])
      super

      @activity_notifications = activity_notifications
    end

    attr_reader :activity_notifications
  end
end
