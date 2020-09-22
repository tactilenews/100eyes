# frozen_string_literal: true

module Notification
  class Notification < ApplicationComponent
    def initialize(show_close: true, **)
      super

      @show_close = show_close
    end

    private

    attr_reader :show_close
  end
end
