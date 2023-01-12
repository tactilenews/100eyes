# frozen_string_literal: true

module ContributorWhatsAppSettings
  class ContributorWhatsAppSettings < ApplicationComponent
    def initialize(contributor:, **)
      super

      @contributor = contributor
    end

    private

    attr_reader :contributor
  end
end
