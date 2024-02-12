# frozen_string_literal: true

module ChatMessageAudio
  class ChatMessageAudio < ApplicationComponent
    def initialize(audios:, **)
      super

      @audios = audios
    end

    private

    attr_reader :audios
  end
end
