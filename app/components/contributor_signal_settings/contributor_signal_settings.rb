# frozen_string_literal: true

module ContributorSignalSettings
  class ContributorSignalSettings < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
