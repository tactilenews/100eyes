# frozen_string_literal: true

module TelegramExplained
  class TelegramExplained < ApplicationComponent
    def initialize(jwt:)
      super

      @jwt = jwt
    end

    private

    attr_reader :jwt
  end
end
