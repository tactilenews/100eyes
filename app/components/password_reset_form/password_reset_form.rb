# frozen_string_literal: true

module PasswordResetForm
  class PasswordResetForm < ApplicationComponent
    def initialize(user:)
      super

      @user = user
    end

    private

    attr_reader :user
  end
end
