# frozen_string_literal: true

module EmptyState
  class EmptyState < ApplicationComponent
    def initialize(custom_icon: nil, **)
      super

      @custom_icon = custom_icon
    end

    private

    attr_reader :custom_icon
  end
end
