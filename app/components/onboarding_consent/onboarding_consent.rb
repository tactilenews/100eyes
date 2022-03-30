# frozen_string_literal: true

module OnboardingConsent
  class OnboardingConsent < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor

    def data_processing_consent_help
      I18n.t('contributor.form.data_processing_consent.help', link: Setting.onboarding_data_protection_link)
    end

    def display_additional_consent_checkbox?
      Setting.onboarding_ask_for_additional_consent && Setting.onboarding_additional_consent_defined?
    end
  end
end
