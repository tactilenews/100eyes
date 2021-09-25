# frozen_string_literal: true

module Notification
  class Notification < ApplicationComponent
    def initialize(show_close: true, show_always: false, **)
      super

      @show_close = show_close
      @show_always = show_always
    end

    private

    attr_reader :show_close, :show_always
  end
end
