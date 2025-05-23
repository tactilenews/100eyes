# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class File < ApplicationJob
      queue_as :default

      attr_reader :organization

      def perform(contributor_id:, file_path:, file_name: nil, caption: nil, render_type: nil, message: nil)
        recipient = Contributor.find(contributor_id)
        @organization = recipient.organization

        message_id = organization.threema_instance.send(type: :file,
                                                        threema_id: recipient.threema_id.upcase,
                                                        file: file_path,
                                                        render_type: render_type,
                                                        file_name: file_name,
                                                        caption: caption)
        return unless message

        message.update(external_id: message_id, sent_at: Time.current)
      rescue RuntimeError => e
        handle_runtime_error(e)
      end

      private

      def handle_runtime_error(exception)
        tags = {}
        if exception.message.match?(/Can't find public key for Threema ID/)
          tags = { support: 'yes' }

          threema_id = exception.message.split('Threema ID').last.strip
          contributor = organization.contributors.where('lower(threema_id) = ?', threema_id.downcase).first

          MarkInactiveContributorInactiveJob.perform_later(contributor_id: contributor.id)
        end
        ErrorNotifier.report(exception, tags: tags)
      end
    end
  end
end
