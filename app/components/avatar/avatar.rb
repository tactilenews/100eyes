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

    def initialize(url: nil, key: 0)
      @url = url
      @key = key
    end

    private

    attr_reader :key

    def url
      @url || fallback_url
    end

    def fallback_url
      file = FALLBACK_IMAGES[key % FALLBACK_IMAGES.length]
      "#{FALLBACK_BASE_URL}/#{file}"
    end
  end
end
