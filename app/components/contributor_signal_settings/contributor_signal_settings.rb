# frozen_string_literal: true

module ContributorSignalSettings
  class ContributorSignalSettings < ApplicationComponent
    def initialize(organization:, contributor:, **)
      super

      @organization = organization
      @contributor = contributor
    end

    private

    attr_reader :contributor, :organization

    def completed_onboarding_text
      if contributor.signal_phone_number.present?
        t('.complete.text.phone_number',
          name: contributor.name,
          phone_number: contributor.signal_phone_number.phony_formatted)
      else

        t('.complete.text.uuid',
          name: contributor.name,
          uuid: contributor.signal_uuid)
      end
    end

    def incomplete_onboarding_text
      t('.incomplete.text',
        name: contributor.name,
        first_name: contributor.first_name,
        date: l(contributor.created_at.to_date))
    end
  end
end
