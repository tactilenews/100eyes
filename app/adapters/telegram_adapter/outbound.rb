# frozen_string_literal: true

module TelegramAdapter
  class Outbound < ApplicationJob
    class << self
      def send!(message)
        recipient = message.recipient
        return unless recipient&.telegram_id

        files = message.files
        if files.present?
          media = files.map { |file| ActiveStorage::Blob.service.path_for(file.attachment.blob.key) }
          TelegramAdapter::Outbound::Photo.perform_later(organization_id: message.organization.id,
                                                         contributor_id: recipient.id,
                                                         media: media,
                                                         message: message)
        else
          TelegramAdapter::Outbound::Text.perform_later(organization_id: message.organization.id,
                                                        contributor_id: recipient.id,
                                                        text: message.text,
                                                        message: message)
        end
      end

      def send_welcome_message!(contributor, organization)
        return unless contributor&.telegram_id

        welcome_message = ["<b>#{organization.onboarding_success_heading}</b>", organization.onboarding_success_text].join("\n")
        TelegramAdapter::Outbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id,
                                                      text: welcome_message)
      end

      def send_unsubsribed_successfully_message!(contributor, organization)
        return unless contributor&.telegram_id

        text = [I18n.t('adapter.shared.unsubscribe.successful'),
                "<em>#{I18n.t('adapter.shared.resubscribe.instructions')}</em>"].join("\n\n")
        TelegramAdapter::Outbound::Text.perform_later(organization_id: organization.id, contributor_id: contributor.id, text: text)
      end

      def send_resubscribe_error_message!(contributor, organization)
        return unless contributor&.telegram_id

        TelegramAdapter::Outbound::Text.perform_later(
          organization_id: organization.id,
          contributor_id: contributor.id,
          text: I18n.t('adapter.shared.resubscribe.failure')
        )
      end
    end
  end
end
