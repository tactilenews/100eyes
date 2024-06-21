# frozen_string_literal: true

module ChatPreview
  class ChatPreview < ApplicationComponent
    def initialize(organization:)
      super

      @organization = organization
    end

    attr_reader :organization
  end
end
