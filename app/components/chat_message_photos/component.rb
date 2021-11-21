# frozen_string_literal: true

module ChatMessagePhotos
  class Component < ApplicationComponent
    def initialize(photos:, **)
      super

      @photos = photos
    end

    private

    attr_reader :photos
  end
end
