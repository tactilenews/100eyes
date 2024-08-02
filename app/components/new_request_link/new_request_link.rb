# frozen_string_literal: true

module NewRequestLink
  class NewRequestLink < ApplicationComponent
    def initialize(organization:)
      @organization = organization

      super
    end

    attr_reader :organization
  end
end
