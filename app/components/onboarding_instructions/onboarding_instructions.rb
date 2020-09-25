# frozen_string_literal: true

module OnboardingInstructions
  class OnboardingInstructions < ApplicationComponent
    def initialize(user:, **)
      super

      @user = user
    end

    private

    attr_reader :user

    def choices
      [
        {
          value: 'telegram-channel',
          label: I18n.t('components.onboarding_instructions.telegram.label')
        },
        {
          value: 'email-channel',
          label: I18n.t('components.onboarding_instructions.email.label')
        }
      ]
    end

    def telegram_steps
      bot_name = Rails.configuration.telegram_bot_name
      steps = I18n.t('components.onboarding_instructions.telegram.steps', telegram_bot_name: bot_name)

      steps.map(&:html_safe)
    end
  end
end
