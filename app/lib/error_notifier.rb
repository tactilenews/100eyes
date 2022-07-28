# frozen_string_literal: true

class ErrorNotifier
  class << self
    def report(exception)
      Sentry.with_scope do |scope|
        context = {
          code: exception.response.code,
          message: exception.response.message,
          headers: exception.response.to_hash,
          body: exception.response.body
        }
        scope.set_context(exception, context)
        Sentry.capture_exception(exception)
      end
    end
  end
end
