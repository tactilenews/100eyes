# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      rescue_from RuntimeError do |exception|
        tags = {}
        if exception.message.match?(/Can't find public key for Threema ID/)
          tags = { support: 'yes' }
          threema_id = exception.message.split('Threema ID').last.strip
          contributor = Contributor.where('lower(threema_id) = ?', threema_id.downcase).first
          return unless contributor

          contributor.update(deactivated_at: Time.current )
          ContributorMarkedInactive.with(contributor_id: contributor.id).deliver_later(User.all)
        end
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
