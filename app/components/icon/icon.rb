# frozen_string_literal: true

module Icon
  class Icon < ApplicationComponent
    def initialize(icon:)
      @icon = icon
    end

    private

    attr_reader :icon

    def url
      "/icons.svg##{icon}"
    end
  end
end
