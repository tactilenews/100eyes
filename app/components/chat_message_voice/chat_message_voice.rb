# frozen_string_literal: true

module ChatMessageVoice
  class ChatMessageVoice < ApplicationComponent
    def initialize(voice:, **)
      @voice = voice
    end

    private

    attr_reader :voice
  end
end
