# frozen_string_literal: true

module AdminStats
  class AdminStats < ApplicationComponent
    def initialize(stats:)
      super

      @stats = stats
    end

    attr_reader :stats

    def email_contributors_count
      stats[:email_contributors_count]
    end

    def threema_contributors_count
      stats[:threema_contributors_count]
    end

    def telegram_contributors_count
      stats[:telegram_contributors_count]
    end

    def signal_contributors_count
      stats[:signal_contributors_count]
    end

    def whats_app_contributors_count
      stats[:whats_app_contributors_count]
    end
  end
end
