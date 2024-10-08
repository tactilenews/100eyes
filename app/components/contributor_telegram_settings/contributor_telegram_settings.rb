# frozen_string_literal: true

module ContributorTelegramSettings
  class ContributorTelegramSettings < ApplicationComponent
    def initialize(organization:, contributor:, **)
      super

      @organization = organization
      @contributor = contributor
    end

    private

    attr_reader :contributor, :organization
  end
end
