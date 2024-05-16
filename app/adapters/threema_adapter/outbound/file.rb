# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      rescue_from RuntimeError do |exception|
        tags = {}
        if exception.message.match?(/Can't find public key for Threema ID/)
          tags = { support: 'yes' }
          threema_id = exception.message.split('Threema ID').last.strip
          contributor = Contributor.where('lower(threema_id) = ?', threema_id.downcase).first
          return unless contributor

          MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id)
        end
        ErrorNotifier.report(exception, tags: tags)
      end

      def self.threema_instance
        @threema_instance ||= Threema.new
      end

      def perform(contributor_id:, file_path:, file_name: nil, caption: nil, render_type: nil, message: nil)
        recipient = Contributor.find_by(id: contributor_id)
        return unless recipient

        message_id = self.class.threema_instance.send(type: :file,
                                                      threema_id: recipient.threema_id.upcase,
                                                      file: file_path,
                                                      render_type: render_type,
                                                      file_name: file_name,
                                                      caption: caption)
        return unless message

        message.update(external_id: message_id)
      end
    end
  end
end
