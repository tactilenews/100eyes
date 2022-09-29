# frozen_string_literal: true

module OnboardingConsent
  class OnboardingConsent < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor

    # rubocop:disable Rails/OutputSafety
    def data_processing_consent_help
      I18n.t('contributor.form.data_processing_consent.help', link: Setting.onboarding_data_protection_link).html_safe
    end
    # rubocop:enable Rails/OutputSafety

    def display_additional_consent_checkbox?
      Setting.onboarding_ask_for_additional_consent? && Setting.onboarding_additional_consent_heading.strip.present?
    end
  end
end
