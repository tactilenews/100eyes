# frozen_string_literal: true

module ContributorCoreDataForm
  class ContributorCoreDataForm < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
