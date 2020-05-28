# frozen_string_literal: true

module UserForm
  class UserForm < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    private

    attr_reader :user
  end
end
