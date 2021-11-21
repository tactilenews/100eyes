# frozen_string_literal: true

module Notifications
  class Component < ApplicationComponent
    def initialize(notifications:, close_after: nil, **)
      super

      @notifications = notifications
      @close_after = close_after
    end

    private

    attr_reader :notifications, :close_after
  end
end
