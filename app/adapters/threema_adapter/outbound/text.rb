# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      rescue_from RuntimeError do |exception|
        tags = exception.message.match?(/Can't find public key for Threema ID/) ? { support: 'yes' } : {}
        ErrorNotifier.report(exception, tags: tags)
      end

      def self.threema_instance
        @threema_instance ||= Threema.new
      end

      def perform(recipient:, text: nil)
        self.class.threema_instance.send(type: :text, threema_id: recipient.threema_id.upcase, text: text)
      end
    end
  end
end
