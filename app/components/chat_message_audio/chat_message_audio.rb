# frozen_string_literal: true

module ChatMessageAudio
  class ChatMessageAudio < ApplicationComponent
    def initialize(audio:, **)
      super

      @audio = audio
    end

    private

    attr_reader :audio
  end
end
