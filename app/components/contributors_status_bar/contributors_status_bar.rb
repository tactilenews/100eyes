# frozen_string_literal: true

module ContributorsStatusBar
  class ContributorsStatusBar < ApplicationComponent
    def initialize(organization:, **)
      super

      @organization = organization
    end

    private

    attr_reader :organization

    def percentage_of_contributors_of_business_plan_used
      number_with_precision(organization.contributors.active.count / organization.business_plan.number_of_contributors.to_f, locale: :en)
    end
  end
end
