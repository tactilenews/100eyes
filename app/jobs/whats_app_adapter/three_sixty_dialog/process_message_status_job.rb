# frozen_string_literal: true

module WhatsAppAdapter
  module ThreeSixtyDialog
    class ProcessMessageStatusJob < ApplicationJob
      def perform(organization_id:, delivery_receipt:)
        organization = Organization.find(organization_id)
        whats_app_phone_number = "+#{delivery_receipt[:recipient_id]}"
        contributor = organization.contributors.find_by(whats_app_phone_number: whats_app_phone_number)

        unless contributor
          exception = WhatsAppAdapter::UnknownContributorError.new(whats_app_phone_number: whats_app_phone_number)
          ErrorNotifier.report(exception)
          return nil
        end

        message = contributor.whats_app_template_messages.find_by(external_id: delivery_receipt[:id]) ||
                  contributor.received_messages.find_by(external_id: delivery_receipt[:id])
        return unless message

        datetime = Time.zone.at(delivery_receipt[:timestamp].to_i).to_datetime

        message.send("#{delivery_receipt[:status]}_at=", datetime)
        message.save!
      end
    end
  end
end
