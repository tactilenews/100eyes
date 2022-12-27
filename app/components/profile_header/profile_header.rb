# frozen_string_literal: true

module ProfileHeader
  class ProfileHeader < ApplicationComponent
    def initialize(organization:, business_plans:, **)
      super

      @organization = organization
      @business_plans = business_plans
    end

    attr_reader :organization, :business_plans
  end
end
