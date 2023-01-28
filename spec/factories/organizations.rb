# frozen_string_literal: true

FactoryBot.define do
  factory :organization do
    name { '100eyes' }
    upgrade_discount { 10 }

    transient do
      users_count { 0 }
      contributors_count { 0 }
      business_plan_name { 'Editorial Basic' }
    end

    users do
      Array.new(users_count) { association(:user, organization: instance) }
    end

    contributors do
      Array.new(contributors_count) { association(:contributor, organization: instance) }
    end

    business_plan do
      attributes = attributes_for(:business_plan, business_plan_name.downcase.split.join('_').to_sym)
      business_plan = BusinessPlan.create_or_find_by(name: business_plan_name)
      business_plan.update(attributes.merge(valid_from: Time.current, valid_until: Time.current + 6.months))
      business_plan
    end
  end
end
