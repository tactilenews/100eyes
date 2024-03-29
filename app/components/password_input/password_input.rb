# frozen_string_literal: true

module PasswordInput
  class PasswordInput < ApplicationComponent
    def initialize(id:, minlength: 0, **)
      super

      @id = id
      @minlength = minlength
    end

    private

    attr_reader :id, :minlength
  end
end
