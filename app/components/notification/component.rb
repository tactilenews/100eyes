# frozen_string_literal: true

module Notification
  class Component < ApplicationComponent
    def initialize(show_close: true, show_always: false, close_after: nil, **)
      super

      @show_close = show_close
      @show_always = show_always
    end

    private

    attr_reader :show_close, :show_always, :close_after

    def attrs
      super.merge({
                    role: 'alert',
                    data: {
                      controller: 'notification',
                      notification_show_always_value: show_always,
                      notification_close_after_value: close_after
                    }
                  })
    end
  end
end
