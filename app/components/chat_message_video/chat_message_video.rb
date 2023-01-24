# frozen_string_literal: true

module ChatMessageVideo
  class ChatMessageVideo < ApplicationComponent
    def initialize(video:)
      super

      @video = video
    end

    attr_reader :video
  end
end
