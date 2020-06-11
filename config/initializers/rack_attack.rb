# frozen_string_literal: true

# Allow 5 requests per 2 seconds per ip address at max
Rack::Attack.throttle('requests per ip', limit: 5, period: 2, &:ip)
