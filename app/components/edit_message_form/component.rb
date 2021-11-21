# frozen_string_literal: true

module EditMessageForm
  class Component < ApplicationComponent
    def initialize(message:, **)
      super

      @message = message
    end

    private

    attr_reader :message
  end
end
