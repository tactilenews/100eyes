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

    def display_name
      return user.name if user.name.present?

      'Anonymer Facebook User'
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
