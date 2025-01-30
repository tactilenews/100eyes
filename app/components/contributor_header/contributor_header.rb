# frozen_string_literal: true

module ContributorHeader
  class ContributorHeader < ApplicationComponent
    def initialize(organization:, contributor:, **)
      super

      @organization = organization
      @contributor = contributor
    end

    private

    attr_reader :organization, :contributor

    def inactive_message
      key, date = if contributor.deactivated_at.present?
                    ['deactivated_at',
                     contributor.deactivated_at.to_date]
                  else
                    ['unsubscribed_at',
                     contributor.unsubscribed_at.to_date]
                  end
      t(".#{key}", date: l(date))
    end
  end
end
