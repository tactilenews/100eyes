# frozen_string_literal: true

module ChatForm
  class ChatForm < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    private

    attr_reader :user
  end
end
