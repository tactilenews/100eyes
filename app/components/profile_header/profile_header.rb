# frozen_string_literal: true

module ProfileHeader
  class ProfileHeader < ApplicationComponent
    def initialize(organization:, business_plans:, **)
      super

      @organization = organization
      @business_plans = business_plans
    end

    attr_reader :organization, :business_plans

    def upgrade_available?
      business_plans.any? { |business_plan| business_plan.price_per_month > organization.business_plan.price_per_month }
    end
  end
end