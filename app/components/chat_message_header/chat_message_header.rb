# frozen_string_literal: true

module ChatMessageHeader
  class ChatMessageHeader < ApplicationComponent
    def initialize(message:)
      super

      @message = message
    end

    private

    attr_reader :message

    def header_content
      if reply?
        reply_header_content
      elsif !attached_to_request?
        header_with_text
      else
        header_with_link
      end
    end

    def reply?
      message.sent_from_contributor?
    end

    def reply_header_content
      if on_conversations_path?
        attached_to_request? ? header_with_link : header_with_text
      else
        link_to_conversations_path
      end
    end

    def on_conversations_path?
      current_page?(conversations_organization_contributor_path(
                      organization_id: message.organization_id,
                      id: message.contributor.id
                    ))
    end

    def attached_to_request?
      message.request.present?
    end

    def header_with_link
      content_tag(:p) do
        sent_by_text +
          request_link
      end
    end

    def header_with_text
      content_tag(:p) do
        sent_by_text
      end
    end

    def request_link
      content_tag(:span, t('.about'), class: 'ChatMessage-requestReference') do # hidden on request show page
        link_to message.request.title, organization_request_path(message.organization_id, id: message.request, anchor: "message-#{message.id}")
      end
    end

    def link_to_conversations_path
      link_to(sent_by_text, conversations_organization_contributor_path(
                              organization_id: message.organization_id,
                              id: message.contributor.id,
                              anchor: "message-#{message.id}"
                            ), data: { turbo: false })
    end

    def sent_by_text
      name = message.sender ? message.sender.first_name : message.organization.project_name
      timestamp = message.sent_from_contributor? ? message.created_at : (message.sent_at || message.created_at)
      I18n.t('components.chat_message.sent_by_x_at',
             name: name, date: date_time(timestamp)).html_safe # rubocop:disable Rails/OutputSafety
    end
  end
end
