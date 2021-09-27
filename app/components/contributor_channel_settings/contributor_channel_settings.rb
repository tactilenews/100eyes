# frozen_string_literal: true

module ContributorChannelSettings
  class ContributorChannelSettings < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
