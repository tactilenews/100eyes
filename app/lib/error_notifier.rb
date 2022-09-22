# frozen_string_literal: true

class ErrorNotifier
  class << self
    def report(exception, context: {}, tags: {})
      Sentry.with_scope do |scope|
        scope.set_context(exception, context) if context.present?
        scope.set_tags(tags) if tags.present?
        Sentry.capture_exception(exception)
      end
    end
  end
end
