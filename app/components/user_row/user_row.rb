# frozen_string_literal: true

module UserRow
  class UserRow < ViewComponent::Base
    include ComponentHelper

    def initialize(user:)
      @user = user
    end

    private

    attr_reader :user
  end
end
