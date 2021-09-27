# frozen_string_literal: true

module Notifications
  class Notifications < ApplicationComponent
    def initialize(notifications:, **)
      super

      @notifications = notifications
    end

    private

    attr_reader :notifications
  end
end
