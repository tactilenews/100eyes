# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    def initialize(user: nil, **)
      super
      @user = user
    end

    private

    attr_reader :user

    def key
      @key = user&.id || 0
    end

    def url
      user&.avatar_url
    end

    def initials
      return '?' unless user

      initials = [user.first_name, user.last_name].map { |name| name&.first }.compact
      return '?' if initials.empty?

      initials.join('')
    end
  end
end
