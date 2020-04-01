# frozen_string_literal: true

module Input
  class Input < ViewComponent::Base
    def initialize(label:)
      @label = label
    end

    def id
      @label.parameterize
    end
  end
end
