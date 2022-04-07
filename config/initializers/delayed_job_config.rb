# frozen_string_literal: true

# queue priority: lower numbers run first; default is 0
Delayed::Worker.queue_attributes = {
  default: { priority: 0 },
  poll_signal_messages: { priority: 1 }
}

Delayed::Worker.max_attempts = 1
Delayed::Worker.destroy_failed_jobs = false

# We use an in-memory cache store that is *not* shared between
# processes. In order to ensure we do not use outdated, cached
# settings values, we need to clear the settings cache every
# time a job is performed.
class DelayedJobClearCachePlugin < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:perform) do
      Setting.clear_cache
    end
  end
end

Delayed::Worker.plugins << DelayedJobClearCachePlugin
