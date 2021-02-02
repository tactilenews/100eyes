# frozen_string_literal: true

module TwoFactorAuthSetup
  class TwoFactorAuthSetup < ApplicationComponent
    def initialize(qr_code: nil)
      super

      @qr_code = qr_code
    end

    private

    attr_reader :qr_code

    def qr_code_as_svg
      # rubocop:disable Rails/OutputSafety
      qr_code.as_svg(
        module_size: 3
      ).html_safe
      # rubocop:enable Rails/OutputSafety
    end

    def user
      helpers.current_user
    end
  end
end
