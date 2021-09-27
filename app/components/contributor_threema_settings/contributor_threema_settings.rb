# frozen_string_literal: true

module ContributorThreemaSettings
  class ContributorThreemaSettings < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
