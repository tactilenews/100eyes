# frozen_string_literal: true

module ChatMessageAudio
  class Component < ApplicationComponent
    def initialize(audio:, **)
      super

      @audio = audio
    end

    private

    attr_reader :audio
  end
end
