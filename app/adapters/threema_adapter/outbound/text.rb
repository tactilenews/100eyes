# frozen_string_literal: true

module ThreemaAdapter
  class Outbound
    class Text < ApplicationJob
      queue_as :default

      rescue_from RuntimeError do |exception|
        tags = {}
        if exception.message.match?(/Can't find public key for Threema ID/)
          tags = { support: 'yes' }
          organization = Organization.find_by(id: arguments.first[:organization_id])
          next unless organization

          threema_id = exception.message.split('Threema ID').last.strip
          contributor = organization.contributors.where('lower(threema_id) = ?', threema_id.downcase).first
          next unless contributor

          MarkInactiveContributorInactiveJob.perform_later(organization_id: organization.id, contributor_id: contributor.id)
        end
        ErrorNotifier.report(exception, tags: tags)
      end

      def self.threema_instance(organization)
        @threema_instance ||= Threema.new(
          api_identity: organization.threemarb_api_identity || Setting.threemarb_api_identity,
          api_secret: organization.threemarb_api_secret || Setting.threemarb_api_secret,
          private_key: Setting.threemarb_private
        )
      end

      def perform(organization_id:, contributor_id:, text: nil, message: nil)
        organization = Organization.find_by(id: organization_id)
        return unless organization

        recipient = organization.contributors.find_by(id: contributor_id)
        # TODO: Throw error if recipient does not belong to organization(?)
        return unless recipient

        message_id = self.class.threema_instance(organization).send(type: :text, threema_id: recipient.threema_id.upcase, text: text)

        return unless message

        message.update(external_id: message_id)
      end
    end
  end
end
