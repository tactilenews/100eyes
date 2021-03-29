# frozen_string_literal: true

SuckerPunch.exception_handler = ->(ex, _klass, _args) { Sentry.capture_exception(ex) }
