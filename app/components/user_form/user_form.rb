# frozen_string_literal: true

module UserForm
  class UserForm < ApplicationComponent
    def initialize(user:)
      @user = user
    end

    private

    attr_reader :user

    def available_tags
      User.all_tags_with_count.to_json
    end
  end
end
