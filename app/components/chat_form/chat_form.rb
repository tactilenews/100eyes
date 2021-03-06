# frozen_string_literal: true

module ChatForm
  class ChatForm < ApplicationComponent
    def initialize(contributor:)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
