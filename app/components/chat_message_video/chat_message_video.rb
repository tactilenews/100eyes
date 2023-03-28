# frozen_string_literal: true

module ChatMessageVideo
  class ChatMessageVideo < ApplicationComponent
    def initialize(videos:)
      super

      @videos = videos
    end

    attr_reader :videos
  end
end
