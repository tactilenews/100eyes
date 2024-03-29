# frozen_string_literal: true

module ContributorStatusToggle
  class ContributorStatusToggle < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
