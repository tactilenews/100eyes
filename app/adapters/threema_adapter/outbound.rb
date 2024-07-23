# frozen_string_literal: true

module ThreemaAdapter
  class Outbound < ApplicationJob
    class << self
      def send!(message)
        return unless message.recipient&.threema_id

        files = message.files

        if files.present?
          send_files(files, message)
        else
          send_text(message)
        end
      end

      def send_welcome_message!(contributor, organization)
        return unless contributor&.threema_id

        welcome_message = ["*#{organization.onboarding_success_heading.strip}*", organization.onboarding_success_text].join("\n")
        ThreemaAdapter::Outbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id,
                                                     text: welcome_message)
      end

      def send_unsupported_content_message!(contributor, organization)
        return unless contributor&.threema_id

        ThreemaAdapter::Outbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id,
                                                     text: organization.threema_unknown_content_message)
      end

      def send_unsubsribed_successfully_message!(contributor, organization)
        return unless contributor&.threema_id

        text = [I18n.t('adapter.shared.unsubscribe.successful'), "_#{I18n.t('adapter.shared.resubscribe.instructions')}_"].join("\n\n")
        ThreemaAdapter::Outbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id, text: text)
      end

      def send_resubscribe_error_message!(contributor, organization)
        return unless contributor&.threema_id

        ThreemaAdapter::Outbound::Text.perform_later(organization_id: organization.id,
                                                     contributor_id: contributor.id,
                                                     text: I18n.t('adapter.shared.resubscribe.failure'))
      end

      def send_files(files, message)
        files.each_with_index do |file, index|
          ThreemaAdapter::Outbound::File.perform_later(
            organization_id: message.organization.id,
            contributor_id: message.recipient.id,
            file_path: ActiveStorage::Blob.service.path_for(file.attachment.blob.key),
            file_name: file.attachment.blob.filename.to_s,
            caption: index.zero? ? message.text : nil,
            render_type: :media,
            message: message
          )
        end
      end

      def send_text(message)
        ThreemaAdapter::Outbound::Text.perform_later(organization_id: message.organization.id,
                                                     contributor_id: message.recipient.id, text: message.text, message: message)
      end
    end
  end
end
