# frozen_string_literal: true

module Avatar
  class Avatar < ApplicationComponent
    delegate :avatar, :avatar?, to: :contributor, prefix: true

    def initialize(contributor: nil, expandable: false, **)
      super
      @contributor = contributor
      @expandable = expandable
    end

    private

    attr_reader :contributor

    def key
      contributor&.id
    end

    def initials
      return '?' unless contributor

      initials = contributor.name.split(' ').map { |part| part&.first }

      return '?' if initials.empty?

      initials.join('')
    end
  end
end
