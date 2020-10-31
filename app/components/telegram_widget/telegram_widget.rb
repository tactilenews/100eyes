# frozen_string_literal: true

module TelegramWidget
  class TelegramWidget < ApplicationComponent
    def initialize(stimulus_target: nil, **)
      super

      @stimulus_target = stimulus_target
    end

    private

    attr_reader :stimulus_target
  end
end
