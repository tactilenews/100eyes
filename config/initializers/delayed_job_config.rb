# frozen_string_literal: true

# queue priority: lower numbers run first; default is 0
Delayed::Worker.queue_attributes = {
  default: { priority: 0 },
  poll_signal_messages: { priority: 1 }
}

Delayed::Worker.max_attempts = 1
