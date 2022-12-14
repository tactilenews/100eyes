# frozen_string_literal: true

module ProfileHeader
  class ProfileHeader < ApplicationComponent
    def initialize(organization:, business_plans:, **)
      super

      @organization = organization
      @business_plans = business_plans
    end

    attr_reader :organization, :business_plans

    def choices
      business_plans.map do |business_plan|
        feature_text = t('.business_plan.features_info',
                         number_of_users: business_plan.number_of_users,
                         number_of_contributors: business_plan.number_of_contributors,
                         number_of_communities: business_plan.number_of_communities)
        if business_plan.hours_of_included_support.positive?
          feature_text << ' ' << t('.business_plan.hours_of_included_support', hours: business_plan.hours_of_included_support)
        end
        {
          value: business_plan.id,
          name: business_plan.name,
          price: business_plan.price_per_month,
          features: feature_text
        }
      end
    end
  end
end
