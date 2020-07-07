# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'].freeze

    def initialize(user: nil, **)
      super
      @user = user
    end

    private

    attr_reader :user

    def key
      user&.id
    end

    def color
      COLORS[key % COLORS.length] if key
    end

    def url
      user&.avatar_url
    end

    def initials
      return '?' unless user

      initials = user.name.split(' ').map { |part| part&.first }

      return '?' if initials.empty?

      initials.join('')
    end
  end
end
