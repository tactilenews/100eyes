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

    def username
      user.name || user.facebook_id
    end

    def channel_icons
      channels = []
      channels << :mail if user.email?
      channels << :telegram if user.telegram?
      channels << :messenger if user.facebook?
      channels
    end
  end
end
