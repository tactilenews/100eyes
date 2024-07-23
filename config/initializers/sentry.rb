# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger]
  config.capture_exception_frame_locals = true
  config.server_name = ENV['APPLICATION_HOSTNAME'] if ENV['APPLICATION_HOSTNAME'].present?
  config.excluded_exceptions -= ['ActiveRecord::RecordNotFound']
  config.excluded_exceptions += ['ErrorNotifier::IgnoredError']
end
