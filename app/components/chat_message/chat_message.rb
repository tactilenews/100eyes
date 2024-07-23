# frozen_string_literal: true

module ChatMessage
  class ChatMessage < ApplicationComponent
    def initialize(message:, hide_actions: false, **)
      super

      @message = message
      @hide_actions = hide_actions
    end

    private

    attr_reader :message, :hide_actions

    def styles
      return super unless @message.highlighted?

      super + [:highlighted]
    end

    def id
      "message-#{message.id}"
    end

    def audio?
      files.any? { |file| file.attachment.blob.content_type.match? /audio/ }
    end

    def image?
      files.any? { |file| file.attachment.blob.content_type.match? /image/ }
    end

    def video?
      files.any? { |file| file.attachment.blob.content_type.match? /video/ }
    end

    def photos
      message.photos
    end

    def image_files
      files.select { |file| file.attachment.blob.content_type.match? /image/ }
    end

    def video_files
      files.select { |file| file.attachment.blob.content_type.match? /video/ }
    end

    def files
      message.files
    end

    def audio_files
      files.select { |file| file.attachment.blob.content_type.match? /audio/ }
    end

    def creator_name
      message.creator_name.presence || I18n.t('components.chat_message.anonymous_creator')
    end

    def sent_by_reference
      name = message.sender ? message.sender.first_name : message.organization.project_name
      sent_by_x_at = I18n.t('components.chat_message.sent_by_x_at', name: name, date: date_time(message.updated_at)).html_safe # rubocop:disable Rails/OutputSafety
      if message.sent_from_contributor?
        link_to_unless(current_page?(conversations_contributor_path(id: message.contributor.id), check_parameters: false), sent_by_x_at, conversations_contributor_path(id: message.contributor.id, anchor: id), data: { turbo: false })
      else
        content_tag(:p, sent_by_x_at)
      end
    end

    def request_link
      link_to message.request.title, request_path(id: message.request, anchor: "message-#{message.id}")
    end

    def warnings
      warnings = []
      warnings << I18n.t('components.chat_message.contains_unknown_content') if message.unknown_content
      warnings << I18n.t('components.chat_message.blocked_by_contributor') if message.blocked
      warnings
    end

    def move_link
      message_request_path(message)
    end
  end
end
