# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    COLORS = ['#F4C317', '#0898FF', '#67D881', '#F4177A'].freeze

    def initialize(contributor: nil, **)
      super
      @contributor = contributor
    end

    private

    attr_reader :contributor

    def key
      contributor&.id
    end

    def color
      COLORS[key % COLORS.length] if key
    end

    def avatar_image?
      contributor&.avatar?
    end

    def avatar_image
      contributor&.avatar
    end

    def initials
      return '?' unless contributor

      initials = contributor.name.split(' ').map { |part| part&.first }

      return '?' if initials.empty?

      initials.join('')
    end
  end
end
