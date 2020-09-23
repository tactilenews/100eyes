# frozen_string_literal: true

module UserForm
  class UserForm < ApplicationComponent
    def initialize(user:)
      @user = user
      @available_tags = User.all_tags
    end

    private

    attr_reader :user, :available_tags
  end
end
