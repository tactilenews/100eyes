# frozen_string_literal: true

# queue priority: lower numbers run first; default is 0
Delayed::Worker.queue_attributes = {
  default: { priority: 0 }
}

Delayed::Worker.max_attempts = 1
Delayed::Worker.destroy_failed_jobs = false
