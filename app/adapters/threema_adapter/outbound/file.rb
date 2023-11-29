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

          contributor.deactivated_at = Time.current
          contributor.save(validate: false)
          ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
          User.admin.find_each do |admin|
            PostmarkAdapter::Outbound.contributor_marked_as_inactive!(admin, contributor)
          end
        end
        ErrorNotifier.report(exception, tags: tags)
      end

      def self.threema_instance
        @threema_instance ||= Threema.new
      end

      def perform(contributor_id:, file_path:, file_name: nil, caption: nil, render_type: nil)
        recipient = Contributor.find(contributor_id)
        return unless recipient

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
