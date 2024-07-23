# frozen_string_literal: true

module GdprModal
  class GdprModal < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end
