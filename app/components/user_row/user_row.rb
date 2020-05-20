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
      channels << :mail if user.email?
      channels << :telegram if user.telegram?
      channels
    end
  end
end
