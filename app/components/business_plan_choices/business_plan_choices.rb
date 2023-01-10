# frozen_string_literal: true

module BusinessPlanChoices
  class BusinessPlanChoices < ApplicationComponent
    def initialize(id:, current_plan:, discount:, choices: [], **)
      super

      @id = id
      @choices = choices
      @current_plan = current_plan
      @discount = discount
    end

    private

    attr_reader :id, :choices, :current_plan, :discount

    def class_list(choice)
      base_class = ['BusinessPlanChoices-label']
      base_class << 'BusinessPlanChoices-checked' if choice[:value] == current_plan.id
      base_class << 'BusinessPlanChoices-disabled' if choice[:price] < current_plan.price_per_month
      base_class.join(' ')
    end

    def price_with_discount(price)
      number_to_currency(price - (price * discount / 100.to_f))
    end
  end
end
