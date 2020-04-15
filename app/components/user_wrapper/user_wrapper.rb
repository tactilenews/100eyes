# frozen_string_literal: true

module UserWrapper
  class UserWrapper < ViewComponent::Base
    def initialize(user:)
      @user = user
    end

    private

    attr_reader :user
  end
end
