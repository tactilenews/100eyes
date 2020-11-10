# frozen_string_literal: true

module TelegramWidget
  class TelegramWidget < ApplicationComponent
    def initialize(jwt:)
      super

      @jwt = jwt
    end

    private

    attr_reader :jwt
  end
end
