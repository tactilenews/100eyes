# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      rescue_from RuntimeError do |exception|
        tags = exception.message.match?(/Can't find public key for Threema ID/) ? { support: 'yes' } : {}
        ErrorNotifier.report(exception, tags: tags)
      end

      def self.threema_instance
        @threema_instance ||= Threema.new
      end

      def perform(recipient:, file_path:, file_name: nil, caption: nil, render_type: nil)
        self.class.threema_instance.send(type: :file,
                                         threema_id: recipient.threema_id.upcase,
                                         file: file_path,
                                         render_type: render_type,
                                         file_name: file_name,
                                         caption: caption)
      end
    end
  end
end
