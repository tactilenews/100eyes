# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent

    def initialize(contributor: nil, **)
      super
      @contributor = contributor
    end

    private

    attr_reader :contributor

    def key
      contributor&.id
    end

    def url
      contributor&.avatar_url
    end

    def initials
      return '?' unless contributor

      initials = contributor.name.split(' ').map { |part| part&.first }

      return '?' if initials.empty?

      initials.join('')
    end
  end
end
