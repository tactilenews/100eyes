# frozen_string_literal: true

Sentry.init do |config|
  config.breadcrumbs_logger = [:active_support_logger]
  config.capture_exception_frame_locals = true
  config.server_name = ENV['APPLICATION_HOSTNAME'] if ENV['APPLICATION_HOSTNAME'].present?
  unignored_exceptions = ['ActiveRecord::RecordNotFound']
  ignored_exceptions = ['ErrorNotifier::IgnoredError']

  config.excluded_exceptions -= unignored_exceptions
  config.excluded_exceptions += ignored_exceptions
end
