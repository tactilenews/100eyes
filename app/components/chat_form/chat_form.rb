# frozen_string_literal: true

module ChatForm
  class ChatForm < ApplicationComponent
    def initialize(contributor:, reply_to: nil)
      super

      @contributor = contributor
      @reply_to = reply_to
    end

    private

    attr_reader :contributor, :reply_to
  end
end
