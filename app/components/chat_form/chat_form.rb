# frozen_string_literal: true

module ChatForm
  class ChatForm < ApplicationComponent
    def initialize(contributor:, reply_to:)
      super

      @contributor = contributor
      @reply_to = reply_to
    end

    private

    attr_reader :contributor
  end
end
