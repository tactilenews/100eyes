# frozen_string_literal: true

module Hero
  # FIXME: this component seems to be unused
  class Hero < ApplicationComponent
    def initialize(organization:)
      @organization = organization

      super
    end

    private

    attr_reader :organization
  end
end
