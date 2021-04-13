# frozen_string_literal: true

module EditMessageForm
  class EditMessageForm < ApplicationComponent
    def initialize(message:, **)
      super

      @message = message
    end

    private

    attr_reader :message
  end
end
