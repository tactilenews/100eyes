# frozen_string_literal: true

module UserRow
  class UserRow < ApplicationComponent

    def initialize(user:, **)
      super

      @user = user
    end

    private

    attr_reader :user

    def url
      user_path(user)
    end

    def channel_icons
      channels = []

      if user.email?
        channels << :mail
      end

      if user.telegram?
        channels << :email
      end

      channels
    end
  end
end
