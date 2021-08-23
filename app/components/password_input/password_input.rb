# frozen_string_literal: true

module PasswordInput
  class PasswordInput < ApplicationComponent
    def initialize(id:, minlength: 0, show_validations: false, **)
      super

      @id = id
      @minlength = minlength
      @show_validations = show_validations
    end

    private

    attr_reader :id, :minlength, :show_validations

    def validations
      {
        minLength: t('.validations.minLength', length: minlength),
        letters: t('.validations.letters'),
        numbers: t('.validations.numbers'),
        special: t('.validations.special')
      }
    end
  end
end
