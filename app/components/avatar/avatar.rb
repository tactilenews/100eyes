# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    FALLBACK_BASE_URL = '/avatars'
    FALLBACK_IMAGES = [
      'fallback-cat.jpg',
      'fallback-dog.jpg',
      'fallback-otter.jpg',
      'fallback-seal.jpg',
      'fallback-squirrel.jpg'
    ].freeze

    def initialize(user: nil, size: :large)
      @user = user
      @size = size
    end

    private

    attr_reader :user, :size

    def key
      @key = user&.id || 0
    end

    def url
      user&.avatar_url || fallback_url
    end

    def fallback_url
      file = FALLBACK_IMAGES[key % FALLBACK_IMAGES.length]
      "#{FALLBACK_BASE_URL}/#{file}"
    end

    def css_class
      "Avatar Avatar-#{size}"
    end
  end
end
