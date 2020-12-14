# frozen_string_literal: true

module OnboardingTelegramForm
  class OnboardingTelegramForm < ApplicationComponent
    def initialize(contributor:, telegram_id:, first_name: nil, last_name: nil, **)
      super

      @contributor = contributor
      @telegram_id = telegram_id
      @first_name = first_name
      @last_name = last_name
    end

    private

    attr_reader :contributor, :first_name, :last_name, :telegram_id
  end
end
