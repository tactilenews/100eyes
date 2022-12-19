# frozen_string_literal: true

module OnboardingChannelButtons
  class OnboardingChannelButtons < ApplicationComponent
    private

    def styles
      return super unless show_signal?

      super + [:even]
    end

    def show_signal?
      Setting.signal_server_phone_number.present?
    end

    def show_whats_app?
      Setting.whats_app_server_phone_number.present?
    end
  end
end
