# frozen_string_literal: true

namespace :settings do
  desc 'Update Setting channels after changing the default value'
  task update_channels_default: :environment do
    current_channels = Setting.channels
    Setting.channels = {
      threema: { configured: Setting.threema_configured?, allow_onboarding: current_channels[:threema] },
      telegram: { configured: Setting.telegram_configured?, allow_onboarding: current_channels[:telegram] },
      email: { configured: Setting.email_configured?, allow_onboarding: current_channels[:email] },
      signal: { configured: Setting.signal_configured?, allow_onboarding: current_channels[:signal] },
      whats_app: { configured: Setting.whats_app_configured?, allow_onboarding: current_channels[:whats_app] }
    }
  end
end
