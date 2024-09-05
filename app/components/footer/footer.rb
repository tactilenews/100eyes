# frozen_string_literal: true

module Footer
  class Footer < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end
