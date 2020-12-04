# frozen_string_literal: true

# TODO: upload our files to an external object storage to reduce load from our application server
Rack::Attack.safelist('allow uploads') do |request|
  request.path.start_with?('/rails/active_storage/')
end

Rack::Attack.throttle('requests per ip', limit: 5, period: 2, &:ip)
