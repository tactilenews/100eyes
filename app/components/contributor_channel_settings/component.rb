# frozen_string_literal: true

module ContributorChannelSettings
  class Component < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
