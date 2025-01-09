# frozen_string_literal: true

module Admin
  class StatsController < Administrate::ApplicationController
    def index
      @stats = {
        email_contributors_count: Contributor.with_email.count,
        threema_contributors_count: Contributor.with_threema.count,
        telegram_contributors_count: Contributor.with_telegram.count,
        signal_contributors_count: Contributor.with_signal.count,
        whats_app_contributors_count: Contributor.with_whats_app.count
      }
      render AdminStats::AdminStats.new(stats: @stats)
    end
  end
end
