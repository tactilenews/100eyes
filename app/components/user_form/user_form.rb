# frozen_string_literal: true

module UserForm
  class UserForm < ApplicationComponent
    def initialize(user:)
      @user = user
      @tags = User.all_tags.map(&:name)
    end

    private

    attr_reader :user, :tags
  end
end
