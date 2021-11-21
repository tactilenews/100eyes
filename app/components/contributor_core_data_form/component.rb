# frozen_string_literal: true

module ContributorCoreDataForm
  class Component < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
