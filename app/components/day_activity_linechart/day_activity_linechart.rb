# frozen_string_literal: true

module DayActivityLinechart
  class DayActivityLinechart < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    private

    attr_reader :organization
  end
end
