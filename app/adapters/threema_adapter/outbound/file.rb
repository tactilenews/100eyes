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

      def perform(args)
        return unless args[:recipient] && args[:file_path]

        self.class.threema_instance.send(type: :file,
                                         threema_id: args[:recipient].threema_id.upcase,
                                         file: args[:file_path],
                                         thumbnail: args[:thumbnail],
                                         file_name: args[:file_name],
                                         caption: args[:caption])
      end
    end
  end
end
