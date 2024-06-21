# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      attr_reader :organization

      def perform(organization_id:, contributor_id:, text: nil, message: nil)
        @organization = Organization.find(organization_id)
        recipient = organization.contributors.find(contributor_id)
        message_id = organization.threema_instance.send(type: :text, threema_id: recipient.threema_id.upcase, text: text)

        return unless message

        message.update(external_id: message_id)
      rescue ActiveRecord::RecordNotFound => e
        ErrorNotifier.report(e)
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

          MarkInactiveContributorInactiveJob.perform_later(organization_id: organization.id, contributor_id: contributor.id)
        end
        ErrorNotifier.report(exception, tags: tags)
      end
    end
  end
end
