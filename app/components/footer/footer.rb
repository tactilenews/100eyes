# frozen_string_literal: true

module Footer
  class Footer < ApplicationComponent
    def initialize(organization:)
      @organization = organization

      super
    end

    attr_reader :organization
  end
end
