# frozen_string_literal: true

module OnboardingInstructions
  class OnboardingInstructions < ApplicationComponent
    def initialize(user:, token:, **)
      super

      @user = user
      @token = token
    end

    private

    attr_reader :user, :token

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
      username = Telegram.bot.username
      steps = I18n.t('components.onboarding_instructions.telegram.steps', username: username)

      steps.map(&:html_safe)
    end
  end
end
