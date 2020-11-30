# frozen_string_literal: true

module PasswordResetForm
  class PasswordResetForm < ApplicationComponent
    def initialize(user: nil)
      super

      @user = user
    end

    private

    attr_reader :user

    def help
      # rubocop:disable Rails/OutputSafety
      I18n.t('helpers.hint.password_reset.password')&.html_safe
      # rubocop:enable Rails/OutputSafety
    end
  end
end
